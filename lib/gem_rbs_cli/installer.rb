module GemRbsCli
  class Installer
    attr_reader :config, :lock, :github_token
    private :config, :lock, :github_token

    def initialize(config:, lock:, github_token:)
      @config = config
      @lock = lock
      @github_token = github_token
    end

    def run
      if lock
        install_from_lock
      else
        install_from_config
      end
    end

    private def install_from_lock
      client = GithubClient.new(github_token: github_token)
      client.fetch_rbs(lock.each_gem.to_a) do |gem, files|
        files.each do |file|
          dir = Pathname("gem_rbs/gems/#{gem.name}/#{gem.version}")
          dir.mkpath
          dir.join(file[:fname]).write(file[:content])
        end
      end
    end

    private def install_from_config
      lock.each_gem do |gem|
      end
    end
  end
end
