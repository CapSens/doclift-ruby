require "json"
require "logger"
require "net/http"
require "openssl"
require "uri"

require "doclift/version"

module Doclift
  require "doclift/error"
  require "doclift/configuration"
  require "doclift/page"
  require "doclift/client"
  require "doclift/user"
  require "doclift/templates"
  require "doclift/template_variables"
  require "doclift/document_requests"
  require "doclift/webhooks/signature_verifier"
  require "doclift/workflows/capabilities"
  require "doclift/workflows/templates"
  require "doclift/workflows/sections"
  require "doclift/workflows/variables"
  require "doclift/workflows/datasets"
  require "doclift/workflows/images"

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def client
      @client ||= Client.new(configuration)
    end

    def reset!
      @configuration = nil
      @client = nil
    end
  end
end
