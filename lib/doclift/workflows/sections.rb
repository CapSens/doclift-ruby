module Doclift
  module Workflows
    module Sections
      KINDS = ["group", "rich_content", "image_with_variable"].freeze
      LAYOUTS = ["inline", "full_page"].freeze
      PAGE_BREAKS = ["continue", "new_page", "own_page"].freeze

      class << self
        def list(template_id:)
          Doclift.client.get(path(template_id))
        end

        def find(template_id:, id:)
          Doclift.client.get("#{path(template_id)}/#{id}")
        end

        def create(template_id:, **attributes)
          Doclift.client.post_json(path(template_id), {section: attributes})
        end

        def update(template_id:, id:, **attributes)
          Doclift.client.patch_json("#{path(template_id)}/#{id}", {section: attributes})
        end

        def destroy(template_id:, id:)
          Doclift.client.delete("#{path(template_id)}/#{id}")
        end

        def move(template_id:, id:, parent_id: nil, position: nil)
          Doclift.client.patch_json(
            "#{path(template_id)}/#{id}/move",
            {section: {parent_id: parent_id, position: position}},
          )
        end

        def duplicate(template_id:, id:)
          Doclift.client.post_json("#{path(template_id)}/#{id}/duplicate", {})
        end

        def update_background(template_id:, section_id:, **attributes)
          Doclift.client.patch_json(
            "#{path(template_id)}/#{section_id}/background",
            {background: attributes},
          )
        end

        def destroy_background(template_id:, section_id:)
          Doclift.client.delete("#{path(template_id)}/#{section_id}/background")
        end

        private

        def path(template_id)
          "/workflows/templates/#{template_id}/sections"
        end
      end
    end
  end
end
