RSpec.describe Doclift::Workflows::Templates do
  let(:base_url) { "https://app.doclift.io/api/v1/workflows/templates" }

  before do
    Doclift.configure { |config| config.api_key = "test_api_key" }
  end

  describe ".list" do
    it "returns a Page of workflow templates", :aggregate_failures do
      stub_request(:get, base_url).to_return(
        status: 200,
        body: JSON.generate([{"id" => 124, "title" => "Relevé"}]),
        headers: {"results" => "1", "results_per_page" => "30", "current_page" => "1", "pages_count" => "1"},
      )

      page = described_class.list

      expect(page.first).to include("id" => 124)
      expect(page.next_page?).to be(false)
    end
  end

  describe ".find" do
    it "fetches one workflow template" do
      stub_request(:get, "#{base_url}/124")
        .to_return(status: 200, body: JSON.generate({"id" => 124, "being_edited" => false}))

      expect(described_class.find(124)).to include("being_edited" => false)
    end
  end

  describe ".create" do
    it "wraps the attributes under the template root key" do
      stub = stub_request(:post, base_url)
        .with(body: JSON.generate({template: {title: "Relevé", description: "Annuel"}}))
        .to_return(status: 201, body: JSON.generate({"id" => 124}))

      expect(described_class.create(title: "Relevé", description: "Annuel")).to eq({"id" => 124})
      expect(stub).to have_been_requested
    end
  end

  describe ".update" do
    it "raises a ConflictError while the builder holds the edit lock" do
      stub_request(:patch, "#{base_url}/124").to_return(
        status: 409,
        body: JSON.generate({"error" => "This workflow is open in the editor."}),
      )

      expect { described_class.update(124, title: "Relevé 2026") }
        .to raise_error(Doclift::ConflictError, /open in the editor/)
    end
  end

  describe ".destroy" do
    it "archives the workflow and returns an empty hash" do
      stub_request(:delete, "#{base_url}/124").to_return(status: 204)

      expect(described_class.destroy(124)).to eq({})
    end
  end

  describe ".validate" do
    it "posts the optional content and scope" do
      stub = stub_request(:post, "#{base_url}/124/validate")
        .with(body: JSON.generate({content: ["<p>x</p>"], scope: "content"}))
        .to_return(status: 200, body: JSON.generate({"publishable" => true, "anomalies" => []}))

      response = described_class.validate(124, content: ["<p>x</p>"], scope: "content")

      expect(response).to include("publishable" => true)
      expect(stub).to have_been_requested
    end

    it "posts an empty body when no content is given" do
      stub = stub_request(:post, "#{base_url}/124/validate")
        .with(body: JSON.generate({}))
        .to_return(status: 200, body: JSON.generate({"publishable" => false}))

      described_class.validate(124)

      expect(stub).to have_been_requested
    end
  end

  describe ".payload_contract" do
    it "fetches the ready-to-post contract" do
      stub_request(:get, "#{base_url}/124/payload_contract")
        .to_return(status: 200, body: JSON.generate({"required" => ["nom"]}))

      expect(described_class.payload_contract(124)).to eq({"required" => ["nom"]})
    end
  end

  describe ".publish" do
    it "posts the publication" do
      stub = stub_request(:post, "#{base_url}/124/publication")
        .to_return(status: 200, body: JSON.generate({"published" => true}))

      expect(described_class.publish(124)).to eq({"published" => true})
      expect(stub).to have_been_requested
    end

    it "raises a ValidationError carrying the blocking anomalies" do
      stub_request(:post, "#{base_url}/124/publication").to_return(
        status: 422,
        body: JSON.generate({
          "error" => "This workflow cannot be published: it carries blocking anomalies.",
          "anomalies" => [{"type" => "empty_document", "section_id" => nil, "variable" => nil}],
        }),
      )

      expect { described_class.publish(124) }.to raise_error(Doclift::ValidationError) do |error|
        expect(error.details["anomalies"]).to contain_exactly(hash_including("type" => "empty_document"))
      end
    end
  end

  describe ".unpublish" do
    it "deletes the publication and returns an empty hash" do
      stub_request(:delete, "#{base_url}/124/publication").to_return(status: 204)

      expect(described_class.unpublish(124)).to eq({})
    end
  end

  describe ".document" do
    it "fetches the export manifest" do
      stub_request(:get, "#{base_url}/124/document")
        .to_return(status: 200, body: JSON.generate({"document" => {"format_version" => 1}}))

      expect(described_class.document(124)).to eq({"document" => {"format_version" => 1}})
    end
  end

  describe ".replace_document" do
    it "sends a PUT with the document root key" do
      stub = stub_request(:put, "#{base_url}/124/document")
        .with(body: JSON.generate({document: {format_version: 1, sections: []}}))
        .to_return(status: 200, body: JSON.generate({"replacement" => true}))

      response = described_class.replace_document(124, {format_version: 1, sections: []})

      expect(response).to include("replacement" => true)
      expect(stub).to have_been_requested
    end
  end

  describe ".theme" do
    it "fetches the theme envelope" do
      stub_request(:get, "#{base_url}/124/theme")
        .to_return(status: 200, body: JSON.generate({"theme" => {"paragraph" => {"font_size" => "11pt"}}}))

      expect(described_class.theme(124)).to include("theme")
    end
  end

  describe ".update_theme" do
    it "sends a PATCH with the theme root key" do
      stub = stub_request(:patch, "#{base_url}/124/theme")
        .with(body: JSON.generate({theme: {h1: {font_size: "22pt"}}}))
        .to_return(status: 200, body: JSON.generate({"theme" => {"h1" => {"font_size" => "22pt"}}}))

      described_class.update_theme(124, {h1: {font_size: "22pt"}})

      expect(stub).to have_been_requested
    end
  end
end
