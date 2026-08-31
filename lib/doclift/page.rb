module Doclift
  class Page
    include Enumerable

    RESULTS_HEADER = "results".freeze
    RESULTS_PER_PAGE_HEADER = "results_per_page".freeze
    CURRENT_PAGE_HEADER = "current_page".freeze
    PAGES_COUNT_HEADER = "pages_count".freeze

    attr_reader :items, :total_results, :per_page, :current_page, :pages_count

    def initialize(items, headers = {})
      @items = items.is_a?(Array) ? items : []
      @total_results = integer_header(headers, RESULTS_HEADER)
      @per_page = integer_header(headers, RESULTS_PER_PAGE_HEADER)
      @current_page = integer_header(headers, CURRENT_PAGE_HEADER)
      @pages_count = integer_header(headers, PAGES_COUNT_HEADER)
    end

    def each(&block)
      items.each(&block)
    end

    def next_page?
      return false if current_page.nil? || pages_count.nil?

      current_page < pages_count
    end

    private

    def integer_header(headers, name)
      value = headers[name]
      value.nil? ? nil : Integer(value, exception: false)
    end
  end
end
