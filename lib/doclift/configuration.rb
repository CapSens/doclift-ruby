module Doclift
  class Configuration
    DEFAULT_API_URL = "https://app.doclift.io/api/v1".freeze
    DEFAULT_OPEN_TIMEOUT = 5
    DEFAULT_READ_TIMEOUT = 120
    DEFAULT_WRITE_TIMEOUT = 60

    attr_accessor :api_key, :logger, :open_timeout, :read_timeout, :write_timeout
    attr_reader :api_url

    def initialize
      @api_url = DEFAULT_API_URL
      @api_key = nil
      @logger = Logger.new(IO::NULL)
      @open_timeout = DEFAULT_OPEN_TIMEOUT
      @read_timeout = DEFAULT_READ_TIMEOUT
      @write_timeout = DEFAULT_WRITE_TIMEOUT
    end

    def api_url=(value)
      @api_uri = nil
      @api_url = value
    end

    def validate!
      return unless api_key.to_s.strip.empty?

      raise ConfigurationError, "Doclift configuration missing: api_key"
    end

    def api_uri
      @api_uri ||= URI.parse(api_url)
    end
  end
end
