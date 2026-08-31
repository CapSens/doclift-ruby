module Doclift
  module Workflows
    module Images
      class << self
        def list(template_id:)
          Doclift.client.get(path(template_id))
        end

        def find(template_id:, token:)
          Doclift.client.get("#{path(template_id)}/#{token}")
        end

        def create(template_id:, **attributes)
          Doclift.client.post_json(path(template_id), {image: attributes})
        end

        def destroy(template_id:, token:)
          Doclift.client.delete("#{path(template_id)}/#{token}")
        end

        private

        def path(template_id)
          "/workflows/templates/#{template_id}/images"
        end
      end
    end
  end
end
