module GemRbsCli
  class Config
    Gem = Struct.new(:source, :name, :version, :branch, keyword_init: true) do
      def owner
        source.split('/')[0]
      end

      def repo_name
        source.split('/')[1]
      end
    end
  end
end
