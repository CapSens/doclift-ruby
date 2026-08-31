module Doclift
  module DocumentRequests
    PATH = "/document_requests".freeze

    TYPE_SYNCHRONOUS = "synchrone".freeze
    TYPE_ASYNCHRONOUS = "asynchrone".freeze

    PRIORITIES = ["critical", "default", "low"].freeze

    STATUS_IN_PROGRESS = "in_progress".freeze
    STATUS_SUCCESS = "success".freeze
    STATUS_ERROR = "error".freeze

    class << self
      def list(page: nil)
        Doclift.client.get_page(PATH, params: {page: page})
      end

      def find(id)
        Doclift.client.get("#{PATH}/#{id}")
      end

      def create(type:, generations:, priority: nil, tag: nil)
        body = {
          type: type,
          tag: tag,
          priority: priority,
          document_generations: generations,
        }.reject { |_key, value| value.nil? }

        Doclift.client.post_json(PATH, {document_request: body})
      end

      def file_url(response, index: 0)
        response.dig("documents_generations", index, "file", "url")
      end

      def generation_status(response, index: 0)
        response.dig("documents_generations", index, "generation_status")
      end

      def generation_error(response, index: 0)
        response.dig("documents_generations", index, "generation_error")
      end

      def status(response)
        response["status"]
      end
    end
  end
end
