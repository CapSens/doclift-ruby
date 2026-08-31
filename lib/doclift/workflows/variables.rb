module Doclift
  module Workflows
    module Variables
      class << self
        def list(template_id:)
          Doclift.client.get(path(template_id))
        end

        def find(template_id:, id:)
          Doclift.client.get("#{path(template_id)}/#{id}")
        end

        def create(template_id:, **attributes)
          Doclift.client.post_json(path(template_id), {variable: attributes})
        end

        def update(template_id:, id:, **attributes)
          Doclift.client.patch_json("#{path(template_id)}/#{id}", {variable: attributes})
        end

        def destroy(template_id:, id:)
          Doclift.client.delete("#{path(template_id)}/#{id}")
        end

        private

        def path(template_id)
          "/workflows/templates/#{template_id}/variables"
        end
      end
    end
  end
end
