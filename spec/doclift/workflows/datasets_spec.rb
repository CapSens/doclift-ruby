RSpec.describe Doclift::Workflows::Datasets do
  let(:base_url) { "https://app.doclift.io/api/v1/workflows/templates/124/datasets" }

  before do
    Doclift.configure { |config| config.api_key = "test_api_key" }
  end

  describe ".list" do
    it "returns the raw, unpaginated array" do
      stub_request(:get, base_url)
        .to_return(status: 200, body: JSON.generate([{"id" => 3, "name" => "Particulier"}]))

      expect(described_class.list(template_id: 124)).to eq([{"id" => 3, "name" => "Particulier"}])
    end
  end

  describe ".find" do
    it "fetches one dataset" do
      stub_request(:get, "#{base_url}/3")
        .to_return(status: 200, body: JSON.generate({"id" => 3}))

      expect(described_class.find(template_id: 124, id: 3)).to eq({"id" => 3})
    end
  end

  describe ".create" do
    it "wraps the attributes under the dataset root key" do
      stub = stub_request(:post, base_url)
        .with(body: JSON.generate({dataset: {name: "Particulier", values: {nom: "Dupont"}}}))
        .to_return(status: 201, body: JSON.generate({"id" => 3}))

      response = described_class.create(template_id: 124, name: "Particulier", values: {nom: "Dupont"})

      expect(response).to eq({"id" => 3})
      expect(stub).to have_been_requested
    end
  end

  describe ".update" do
    it "sends a PATCH on the nested route" do
      stub = stub_request(:patch, "#{base_url}/3")
        .with(body: JSON.generate({dataset: {name: "Professionnel"}}))
        .to_return(status: 200, body: JSON.generate({"id" => 3}))

      described_class.update(template_id: 124, id: 3, name: "Professionnel")

      expect(stub).to have_been_requested
    end
  end

  describe ".destroy" do
    it "deletes the dataset and returns an empty hash" do
      stub_request(:delete, "#{base_url}/3").to_return(status: 204)

      expect(described_class.destroy(template_id: 124, id: 3)).to eq({})
    end
  end
end
