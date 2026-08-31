module Doclift
  module Templates
    PATH = "/templates".freeze

    CATEGORY_CUSTOM = "custom".freeze
    CATEGORY_FILLABLE_FORM = "fillable_form".freeze
    CATEGORY_WORKFLOW = "workflow".freeze

    class << self
      def list(page: nil)
        Doclift.client.get_page(PATH, params: {page: page})
      end

      def find(id)
        Doclift.client.get("#{PATH}/#{id}")
      end

      def create(**attributes)
        Doclift.client.post_json(PATH, {template: attributes})
      end

      def update(id, **attributes)
        Doclift.client.patch_json("#{PATH}/#{id}", {template: attributes})
      end

      def destroy(id)
        Doclift.client.delete("#{PATH}/#{id}")
      end

      def publish(id)
        Doclift.client.put_json("#{PATH}/#{id}/publish", {})
      end

      def unpublish(id)
        Doclift.client.put_json("#{PATH}/#{id}/unpublish", {})
      end
    end
  end
end
