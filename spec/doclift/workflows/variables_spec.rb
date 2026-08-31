RSpec.describe Doclift::Workflows::Variables do
  let(:base_url) { "https://app.doclift.io/api/v1/workflows/templates/124/variables" }

  before do
    Doclift.configure { |config| config.api_key = "test_api_key" }
  end

  describe ".list" do
    it "returns the raw, unpaginated array" do
      stub_request(:get, base_url)
        .to_return(status: 200, body: JSON.generate([{"id" => 77, "name" => "nom"}]))

      expect(described_class.list(template_id: 124)).to eq([{"id" => 77, "name" => "nom"}])
    end
  end

  describe ".find" do
    it "fetches one variable" do
      stub_request(:get, "#{base_url}/77")
        .to_return(status: 200, body: JSON.generate({"id" => 77}))

      expect(described_class.find(template_id: 124, id: 77)).to eq({"id" => 77})
    end
  end

  describe ".create" do
    it "wraps the attributes under the variable root key, name included" do
      stub = stub_request(:post, base_url)
        .with(body: JSON.generate({
          variable: {
            name: "investissements",
            description: "Les lignes",
            field_type: "collection",
            fields: [{name: "produit", description: "Le produit", required: true}],
          },
        }))
        .to_return(status: 201, body: JSON.generate({"id" => 77}))

      response = described_class.create(
        template_id: 124,
        name: "investissements",
        description: "Les lignes",
        field_type: "collection",
        fields: [{name: "produit", description: "Le produit", required: true}],
      )

      expect(response).to eq({"id" => 77})
      expect(stub).to have_been_requested
    end

    it "surfaces the plural errors body of a refused name" do
      stub_request(:post, base_url).to_return(
        status: 422,
        body: JSON.generate({"errors" => ["Name n'est pas valide"]}),
      )

      expect { described_class.create(template_id: 124, name: "Nom Invalide", description: "x") }
        .to raise_error(Doclift::ValidationError, "Name n'est pas valide")
    end
  end

  describe ".update" do
    it "sends a PATCH on the nested route" do
      stub = stub_request(:patch, "#{base_url}/77")
        .with(body: JSON.generate({variable: {required: false}}))
        .to_return(status: 200, body: JSON.generate({"id" => 77}))

      described_class.update(template_id: 124, id: 77, required: false)

      expect(stub).to have_been_requested
    end
  end

  describe ".destroy" do
    it "deletes the variable and returns an empty hash" do
      stub_request(:delete, "#{base_url}/77").to_return(status: 204)

      expect(described_class.destroy(template_id: 124, id: 77)).to eq({})
    end
  end
end
