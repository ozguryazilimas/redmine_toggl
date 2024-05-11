
class TogglService
  module Connection

    HTTPS = 'https'

    def setup_authentication(args)
      @username = args[:username]
      @password = args[:password]
    end

    def http_call(http_method, url_path, payload = {}, http_headers = {})
      uri = URI.parse(format('%s/%s', @toggl_url, url_path))
      response_is_json = true

      case http_method
      when :get
        uri.query = URI.encode_www_form(payload) if payload.present?
        request = Net::HTTP::Get.new(uri)
      when :post
        request = Net::HTTP::Post.new(uri)
        if payload.present?
          request.body = payload.is_a?(String) ? payload : payload.to_json
        end
      when :delete
        request = Net::HTTP::Delete.new(uri)
        response_is_json = false
      when :put
        request = Net::HTTP::Put.new(uri)

        if payload.present?
          request.body = payload.is_a?(String) ? payload : payload.to_json
        end
      else
        raise :unknown_http_method
      end

      if http_headers.blank?
        request['Accept'] = 'application/json'
        request['Content-Type'] = 'application/json' # if http_method == :post
      else
        http_headers.each do |key, value|
          request[key] = value
        end
      end

      request_options = {
        :use_ssl => uri.scheme == HTTPS
      }

      # request["Authorization"] =  format('Basic %s', Base64::encode64("#{@username}:#{@password}"))
      request.basic_auth @username, @password

      response_raw = Net::HTTP.start(uri.hostname, uri.port, request_options) do |http|
        http.request(request)
      end

      response = response_is_json ? JSON.parse(response_raw.body) : response_raw.body
      response = response['data'] if response.respond_to?(:has_key?) && response.has_key?('data')

      [response_raw.code, response]
    rescue => e
      Rails.logger.error "RedmineToggl received error #{e.inspect}"
      raise e
      [response_raw.code, response_raw.body]
    end

  end
end

