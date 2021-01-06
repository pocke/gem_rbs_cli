module GemRbsCli
  module GithubClient
    def self.new(github_token:)
      if github_token
        V4.new(github_token: github_token)
      else
        Curl.new
      end
    end

    class Curl
      def fetch_rbs(gems, &block)
        raise NotImplementedError
      end
    end

    class V4
      attr_reader :github_token
      private :github_token

      def initialize(github_token:)
        @github_token = github_token
      end

      def fetch_rbs(gems, &block)
        builder = QueryBuilder.new

        gems.each do |gem|
          path = "#{gem.branch}:gems/#{gem.name}/#{gem.version}"
          builder.add(gem, <<~GRAPHQL, { 'path' => path, 'owner': gem.owner, 'repo_name' => gem.repo_name })
            repository(owner: $owner, name: $repo_name) {
              object(expression: $path) {
                ... on Tree {
                  entries {
                    name
                    object {
                      ... on Blob {
                        isTruncated
                        text
                      }
                    }
                  }
                }
              }
            }
          GRAPHQL
        end

        resp = req(query: builder.query, variables: builder.variables)

        gems.each do |gem|
          r = builder.fetch_from(resp[:data], gem)
          binding.irb
          files = r.dig(:object, :entries).map do |entry|
            fname = entry[:name]
            if fname.end_with?('.rbs')
              content =
                if entry.dig(:object, :isTruncated)
                  # FIXME
                  `curl -H 'Accept: application/vnd.github.v3.raw' -H Authorization: token #{github_token} https://api.github.com/repos/ruby/gem_rbs/contents/gems/#{gem.name}/#{gem.version}/#{fname}`
                else
                  entry.dig(:object, :text)
                end
              { content: content, fname: fname }
            end
          end.compact

          # TODO: yield sha
          block.call gem, files
        end
      end

      private def req(query)
        http = Net::HTTP.new("api.github.com", 443)
        http.use_ssl = true
        header = {
          "Authorization" => "Bearer #{github_token}",
          'Content-Type' => 'application/json',
          'User-Agent' => 'gem_rbs client',
        }
        resp = http.request_post('/graphql', JSON.generate(query), header)
        JSON.parse(resp.body, symbolize_names: true).tap do |content|
          raise content[:errors].inspect if content[:errors]
        end
      end
    end

    class QueryBuilder
      attr_reader :variables

      def initialize
        @queries = []
        @variables = {}
        @table = {}
      end

      def add(key, query, variables)
        name = '_' + SecureRandom.hex(8)
        @table[key] = name.to_sym

        query = query.dup
        variables = variables.transform_keys do |key|
          next key unless @variables.key?(key)

          new_key = key + '_' + SecureRandom.hex(8)
          query.gsub!(key, new_key)
          new_key
        end

        @queries << "#{name}:#{query}"
        @variables.merge!(variables)
      end

      def fetch_from(data, key)
        data[@table[key]]
      end

      def query
        # NOTE: It does not allow non-String type for variables
        "query(#{variables.keys.map { |v| "$#{v}: String!" }.join(',')}) { #{@queries.join("\n")} }"
      end
    end
  end
end
