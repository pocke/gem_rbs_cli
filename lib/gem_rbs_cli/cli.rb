module GemRbsCli
  class CLI
    def initialize(argv)
      @argv = argv
    end

    def run
      case command
      when 'install'
        run_install
      when 'update'
        run_update
      when 'help'
        help
      else
        help
        exit 1
      end
    rescue Errors::Error => ex
      $stderr.puts ex
      exit 1
    end

    def run_install
      lock = Config.load_lock
      token = github_token
      raise Errors::Error.new("You must need to specify GITHUB_TOKEN") if !lock && !token

      Installer.new(config: config!, lock: lock, github_token: token).run
    end

    def run_update
      token = github_token
      raise Errors::Error.new("gem_rbs update needs GITHUB_TOKEN environment variable") unless token

      Updater.new(config: config!, github_token: github_token).run
    end

    private def command
      @argv[0]
    end

    private def github_token
      ENV['GITHUB_TOKEN']
    end

    private def config!
      Config.load_config or raise Errors::Error.new("#{Config::CONFIG_PATH} doesn't exist")
    end
  end
end
