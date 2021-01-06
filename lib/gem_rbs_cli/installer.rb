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
      # TODO: If lock and config has difference, it doesn't work
      if lock
        install_from_lock
      else
        install_from_config
      end
    end

    private def install_from_lock
      client = GithubClient.new(github_token: github_token)
      client.fetch_rbs(lock.each_gem.to_a) do |gem, files|
        # TODO: remove old files
        files.each do |file|
          dir = Pathname("gem_rbs/gems/#{gem.name}/#{gem.version}")
          dir.mkpath
          dir.join(file[:fname]).write(file[:content])
        end
      end
    end

    private def install_from_config
      client = GithubClient.new(github_token: github_token)

      new_lock = Config.new('gems: []')

      client.fetch_rbs(config.each_gem.to_a) do |gem, files|
        new_gem = gem.to_h { |k, v| [k.to_s, v] }
        new_gem['files'] = []
        new_lock.add_gem new_gem

        # TODO: Skip install if it is already downloaded
        # TODO: Fix branch by sha1
        # TODO: remove old files
        files.each do |file|
          dir = Pathname("gem_rbs/gems/#{gem.name}/#{gem.version}")
          dir.mkpath
          dir.join(file[:fname]).write(file[:content])

          new_gem['files'] << file[:fname]
        end
      end

      new_lock.dump_to Config::LOCK_PATH
    end
  end
end
