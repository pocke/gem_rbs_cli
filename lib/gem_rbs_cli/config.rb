module GemRbsCli
  CONFIG_PATH = Pathname('.gem_rbs.yaml')
  LOCK_PATH = Pathname('.gem_rbs.lock.yaml')

  DEFAULT_SOURCE = 'ruby/gem_rbs'
  DEFAULT_BRANCH = 'main'

  # Format:
  #   source: ruby/gem_rbs
  #   gems:
  #     - 'activesupport:6.0.3.4'
  #     - name: 'activesupport:6.0.3.4'
  #     - name: activesupport
  #       version: 6.0.3.4
  #     - name: 'activesupport'
  #       version: 6.0.3.4
  #       source: ruby/gem_rbs
  #       branch: develop
  #       files: # lockfile only
  #         - path/to/file.rbs
  class Config
    def self.load_config
      return unless CONFIG_PATH.exist?

      new CONFIG_PATH.read
    end

    def self.load_lock
      return unless LOCK_PATH.exist?

      new LOCK_PATH.read
    end

    def initialize(yaml)
      @config = YAML.load(yaml)
    end

    def each_gem(&block)
      return enum_for __method__ unless block_given?

      @config['gems'].each do |gem|
        case gem
        when String
          name, version = gem.split(':')
        when Hash
          name, version = gem['name'].split(':')
          version ||= gem['version']
          source = gem['source'] || DEFAULT_SOURCE
          branch = gem['branch'] || DEFAULT_BRANCH
        else
          raise "Unexpected: #{gem}"
        end

        raise Errors::Error.new("Gem name must be specified") unless name
        raise Errors::Error.new("Gem version must be specified") unless version

        block.call Gem.new(name: name, version: version, source: source, branch: branch)
      end
    end
  end
end
