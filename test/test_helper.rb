require 'minitest'
require 'minitest/autorun'
require 'tmpdir'

require 'gem_rbs_cli'


module TestHelper
  extend self

  def mktmpdir(&block)
    Dir.mktmpdir('gem_rbs_cli-test') do |dir|
      Dir.chdir(dir) do
        block.call Pathname(dir)
      end
    end
  end

  def without_token(&block)
    token = ENV.delete('GITHUB_TOKEN')
    block.call
  ensure
    ENV['GITHUB_TOKEN'] = token
  end
end
