
module RedmineToggl
  module Patches
    module Togglv8ConnectionPatch

      def self.included(base)
        base.class_eval do

          def self.open(username = nil, password = API_TOKEN, url = nil, opts = {})
            raise 'Missing URL' if url.nil?

            Faraday.new(:url => url, :ssl => {:verify => true}) do |faraday|
              faraday.request :url_encoded
              faraday.response :logger, Logger.new('faraday.log') if opts[:log]
              faraday.adapter Faraday.default_adapter
              faraday.headers = { "Content-Type" => "application/json" }

              if ::Faraday::VERSION >= '2.0.0'
                faraday.request :authorization, :basic, username, password
              elsif ::Faraday::VERSION >= '1.7.1'
                faraday.request :basic_auth, username, password
              else
                faraday.basic_auth username, password
              end
            end
          end

        end
      end

    end
  end
end

