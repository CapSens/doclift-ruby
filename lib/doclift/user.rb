module Doclift
  module User
    PATH = "/user".freeze

    class << self
      def show
        Doclift.client.get(PATH)
      end
    end
  end
end
