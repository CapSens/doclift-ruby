module Doclift
  class Client
    NETWORK_ERRORS = [
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EHOSTUNREACH,
      Errno::ENETUNREACH,
      Errno::EPIPE,
      Errno::ETIMEDOUT,
      EOFError,
      IOError,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::OpenTimeout,
      Net::ProtocolError,
      Net::ReadTimeout,
      Net::WriteTimeout,
      OpenSSL::SSL::SSLError,
      SocketError,
    ].freeze

    PAGINATION_HEADERS = [
      Page::RESULTS_HEADER,
      Page::RESULTS_PER_PAGE_HEADER,
      Page::CURRENT_PAGE_HEADER,
      Page::PAGES_COUNT_HEADER,
    ].freeze

    def initialize(configuration)
      @configuration = configuration
    end

    def get(path, params: nil)
      request(Net::HTTP::Get.new(uri_for(path, params: params), default_headers))
    end

    def get_page(path, params: nil)
      req = Net::HTTP::Get.new(uri_for(path, params: params), default_headers)
      response = perform(req)
      Page.new(parse_body(response.body), pagination_headers(response))
    end

    def post_json(path, body)
      write_json(Net::HTTP::Post, path, body)
    end

    def patch_json(path, body)
      write_json(Net::HTTP::Patch, path, body)
    end

    def put_json(path, body)
      write_json(Net::HTTP::Put, path, body)
    end

    def delete(path)
      request(Net::HTTP::Delete.new(uri_for(path), default_headers))
    end

    private

    attr_reader :configuration

    def write_json(verb_class, path, body)
      req = verb_class.new(uri_for(path), default_headers)
      req.body = JSON.generate(body)
      request(req)
    end

    def uri_for(path, params: nil)
      base = configuration.api_uri
      cleaned = path.start_with?("/") ? path : "/#{path}"
      query = params_to_query(params)
      URI.parse("#{base.scheme}://#{base.host}#{port_suffix(base)}#{base.path}#{cleaned}#{query}")
    end

    def params_to_query(params)
      compacted = (params || {}).reject { |_key, value| value.nil? }
      compacted.empty? ? "" : "?#{URI.encode_www_form(compacted)}"
    end

    def port_suffix(uri)
      default_port = (uri.scheme == "https") ? 443 : 80
      (uri.port == default_port) ? "" : ":#{uri.port}"
    end

    def default_headers
      {
        "X-Api-Key" => configuration.api_key.to_s,
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "User-Agent" => "doclift-ruby/#{Doclift::VERSION}",
      }
    end

    def request(req)
      parse_body(perform(req).body)
    end

    def perform(req)
      configuration.validate!
      configuration.logger.debug { "[Doclift] #{req.method} #{req.uri}" }

      response = http_for(req.uri).request(req)

      unless (200..299).cover?(response.code.to_i)
        raise ApiError.from_response(response.code.to_i, parse_body(response.body))
      end

      response
    rescue *NETWORK_ERRORS => exception
      raise ConnectionError.new(
        "Doclift connection error: #{exception.class}: #{exception.message}",
        cause_class: exception.class,
      )
    end

    def http_for(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = configuration.open_timeout
      http.read_timeout = configuration.read_timeout
      http.write_timeout = configuration.write_timeout
      http
    end

    def pagination_headers(response)
      PAGINATION_HEADERS.each_with_object({}) do |name, headers|
        value = response[name] || response[name.tr("_", "-")]
        headers[name] = value unless value.nil?
      end
    end

    def parse_body(body)
      return {} if body.nil? || body.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      {"raw_body" => body}
    end
  end
end
