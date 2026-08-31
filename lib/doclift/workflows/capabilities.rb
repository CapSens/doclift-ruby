module Doclift
  module Workflows
    module Capabilities
      PATH = "/workflows/capabilities".freeze

      class << self
        def show
          Doclift.client.get(PATH)
        end
      end
    end
  end
end
