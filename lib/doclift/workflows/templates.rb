module Doclift
  module Workflows
    module Templates
      PATH = "/workflows/templates".freeze

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

        def validate(id, content: nil, scope: nil)
          body = {content: content, scope: scope}.reject { |_key, value| value.nil? }

          Doclift.client.post_json("#{PATH}/#{id}/validate", body)
        end

        def payload_contract(id)
          Doclift.client.get("#{PATH}/#{id}/payload_contract")
        end

        def publish(id)
          Doclift.client.post_json("#{PATH}/#{id}/publication", {})
        end

        def unpublish(id)
          Doclift.client.delete("#{PATH}/#{id}/publication")
        end

        def document(id)
          Doclift.client.get("#{PATH}/#{id}/document")
        end

        def replace_document(id, document)
          Doclift.client.put_json("#{PATH}/#{id}/document", {document: document})
        end

        def theme(id)
          Doclift.client.get("#{PATH}/#{id}/theme")
        end

        def update_theme(id, theme)
          Doclift.client.patch_json("#{PATH}/#{id}/theme", {theme: theme})
        end
      end
    end
  end
end
