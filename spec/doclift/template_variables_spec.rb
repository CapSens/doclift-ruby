RSpec.describe Doclift::TemplateVariables do
  let(:base_url) { "https://app.doclift.io/api/v1" }

  before do
    Doclift.configure { |config| config.api_key = "test_api_key" }
  end

  describe ".list" do
    it "returns the raw, unpaginated array" do
      stub_request(:get, "#{base_url}/templates/1/variables")
        .to_return(status: 200, body: JSON.generate([{"id" => 9, "title" => "nom"}]))

      expect(described_class.list(template_id: 1)).to eq([{"id" => 9, "title" => "nom"}])
    end
  end

  describe ".create" do
    it "wraps the attributes under the variable root key" do
      stub = stub_request(:post, "#{base_url}/templates/1/variables")
        .with(body: JSON.generate({variable: {title: "nom", description: "Nom", field_type: "text"}}))
        .to_return(status: 201, body: JSON.generate({"id" => 9}))

      response = described_class.create(template_id: 1, title: "nom", description: "Nom", field_type: "text")

      expect(response).to eq({"id" => 9})
      expect(stub).to have_been_requested
    end
  end

  describe ".update" do
    it "sends a PATCH on the nested route" do
      stub = stub_request(:patch, "#{base_url}/templates/1/variables/9")
        .with(body: JSON.generate({variable: {seed_value: "Dupont"}}))
        .to_return(status: 200, body: JSON.generate({"id" => 9}))

      described_class.update(template_id: 1, id: 9, seed_value: "Dupont")

      expect(stub).to have_been_requested
    end
  end

  describe ".destroy" do
    it "deletes the variable and returns an empty hash" do
      stub_request(:delete, "#{base_url}/templates/1/variables/9").to_return(status: 204)

      expect(described_class.destroy(template_id: 1, id: 9)).to eq({})
    end
  end
end
