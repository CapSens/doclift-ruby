RSpec.describe Doclift::Workflows::Sections do
  let(:base_url) { "https://app.doclift.io/api/v1/workflows/templates/124/sections" }

  before do
    Doclift.configure { |config| config.api_key = "test_api_key" }
  end

  describe ".list" do
    it "returns the raw tree envelope" do
      stub_request(:get, base_url)
        .to_return(status: 200, body: JSON.generate({"tree" => []}))

      expect(described_class.list(template_id: 124)).to eq({"tree" => []})
    end
  end

  describe ".find" do
    it "fetches one section" do
      stub_request(:get, "#{base_url}/512")
        .to_return(status: 200, body: JSON.generate({"section" => {"id" => 512}}))

      expect(described_class.find(template_id: 124, id: 512)).to eq({"section" => {"id" => 512}})
    end
  end

  describe ".create" do
    it "wraps the attributes under the section root key" do
      stub = stub_request(:post, base_url)
        .with(body: JSON.generate({section: {kind: "rich_content", title: "Corps", parent_id: 500}}))
        .to_return(status: 201, body: JSON.generate({"section" => {"id" => 512}, "tree" => []}))

      response = described_class.create(template_id: 124, kind: "rich_content", title: "Corps", parent_id: 500)

      expect(response).to include("section", "tree")
      expect(stub).to have_been_requested
    end
  end

  describe ".update" do
    it "sends a PATCH with the section root key" do
      stub = stub_request(:patch, "#{base_url}/512")
        .with(body: JSON.generate({section: {content: "<p>x</p>"}}))
        .to_return(status: 200, body: JSON.generate({"section" => {"id" => 512}, "tree" => []}))

      described_class.update(template_id: 124, id: 512, content: "<p>x</p>")

      expect(stub).to have_been_requested
    end
  end

  describe ".destroy" do
    it "returns the remaining tree rather than an empty body" do
      stub_request(:delete, "#{base_url}/512")
        .to_return(status: 200, body: JSON.generate({"tree" => []}))

      expect(described_class.destroy(template_id: 124, id: 512)).to eq({"tree" => []})
    end
  end

  describe ".move" do
    it "sends both keys even when nil, since nil means root and append" do
      stub = stub_request(:patch, "#{base_url}/512/move")
        .with(body: JSON.generate({section: {parent_id: nil, position: nil}}))
        .to_return(status: 200, body: JSON.generate({"section" => {"id" => 512}, "tree" => []}))

      described_class.move(template_id: 124, id: 512)

      expect(stub).to have_been_requested
    end

    it "sends the target parent and position" do
      stub = stub_request(:patch, "#{base_url}/512/move")
        .with(body: JSON.generate({section: {parent_id: 500, position: 2}}))
        .to_return(status: 200, body: JSON.generate({"section" => {"id" => 512}, "tree" => []}))

      described_class.move(template_id: 124, id: 512, parent_id: 500, position: 2)

      expect(stub).to have_been_requested
    end
  end

  describe ".duplicate" do
    it "posts an empty body" do
      stub = stub_request(:post, "#{base_url}/512/duplicate")
        .with(body: JSON.generate({}))
        .to_return(status: 201, body: JSON.generate({"section" => {"id" => 513}, "tree" => []}))

      described_class.duplicate(template_id: 124, id: 512)

      expect(stub).to have_been_requested
    end
  end

  describe ".update_background" do
    it "sends the base64 upload under the background root key" do
      stub = stub_request(:patch, "#{base_url}/512/background")
        .with(body: JSON.generate({
          background: {filename: "cerfa.png", content_type: "image/png", data: "aVZCT1J3MEtHZ28="},
        }))
        .to_return(status: 200, body: JSON.generate({"section" => {"id" => 512}, "tree" => []}))

      described_class.update_background(
        template_id: 124,
        section_id: 512,
        filename: "cerfa.png",
        content_type: "image/png",
        data: "aVZCT1J3MEtHZ28=",
      )

      expect(stub).to have_been_requested
    end
  end

  describe ".destroy_background" do
    it "returns the section and tree envelope" do
      stub_request(:delete, "#{base_url}/512/background")
        .to_return(status: 200, body: JSON.generate({"section" => {"id" => 512}, "tree" => []}))

      expect(described_class.destroy_background(template_id: 124, section_id: 512)).to include("tree")
    end
  end
end
