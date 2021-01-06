require 'test_helper'

class CliTest < Minitest::Test
  CONFIG = <<~YAML
    gems:
      - name: activesupport
        version: 6.0.3.2
        branch: 737ad93497b5fbd5253829c4595e2da2d4a885e3
  YAML
  LOCK = <<~YAML
    gems:
      - name: activesupport
        source: 'ruby/gem_rbs'
        version: 6.0.3.2
        branch: 737ad93497b5fbd5253829c4595e2da2d4a885e3
        files:
          - activesupport-generated.rbs
          - patch.rbs
  YAML

  def test_install_from_config
    TestHelper.mktmpdir do |dir|
      dir.join(GemRbsCli::Config::CONFIG_PATH).write(CONFIG)
      GemRbsCli::CLI.new(['install']).run_install

      assert dir.join('gem_rbs/gems/activesupport/6.0.3.2/activesupport-generated.rbs').exist?
      assert dir.join('gem_rbs/gems/activesupport/6.0.3.2/patch.rbs').exist?

      lock = YAML.load(dir.join('.gem_rbs.lock.yaml').read)
      assert_equal YAML.load(LOCK), lock
    end
  end

  def test_install_from_config_without_token
    TestHelper.without_token do
      TestHelper.mktmpdir do |dir|
        dir.join(GemRbsCli::Config::CONFIG_PATH).write(CONFIG)
        
        ex = assert_raises { GemRbsCli::CLI.new(['install']).run_install }
        assert ex.is_a?(GemRbsCli::Errors::Error)
        assert_equal 'You must need to specify GITHUB_TOKEN', ex.message
      end
    end
  end

  def test_install_from_lock
    TestHelper.mktmpdir do |dir|
      dir.join(GemRbsCli::Config::CONFIG_PATH).write(CONFIG)
      dir.join(GemRbsCli::Config::LOCK_PATH).write(LOCK)

      GemRbsCli::CLI.new(['install']).run_install

      assert dir.join('gem_rbs/gems/activesupport/6.0.3.2/activesupport-generated.rbs').exist?
      assert dir.join('gem_rbs/gems/activesupport/6.0.3.2/patch.rbs').exist?
    end
  end

  def test_install_from_lock_without_token
    TestHelper.without_token do
      TestHelper.mktmpdir do |dir|
        dir.join(GemRbsCli::Config::CONFIG_PATH).write(CONFIG)
        dir.join(GemRbsCli::Config::LOCK_PATH).write(LOCK)

        GemRbsCli::CLI.new(['install']).run_install

        assert dir.join('gem_rbs/gems/activesupport/6.0.3.2/activesupport-generated.rbs').exist?
        assert dir.join('gem_rbs/gems/activesupport/6.0.3.2/patch.rbs').exist?
      end
    end
  end
end
