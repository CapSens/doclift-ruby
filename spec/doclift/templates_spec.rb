RSpec.describe Doclift::Templates do
  let(:base_url) { "https://app.doclift.io/api/v1" }

  before do
    Doclift.configure { |config| config.api_key = "test_api_key" }
  end

  describe ".list" do
    it "returns a Page of templates", :aggregate_failures do
      stub_request(:get, "#{base_url}/templates?page=2").to_return(
        status: 200,
        body: JSON.generate([{"id" => 1, "title" => "Contrat"}]),
        headers: {"results" => "31", "results_per_page" => "30", "current_page" => "2", "pages_count" => "2"},
      )

      page = described_class.list(page: 2)

      expect(page).to be_a(Doclift::Page)
      expect(page.first).to include("title" => "Contrat")
      expect(page.current_page).to eq(2)
    end
  end

  describe ".find" do
    it "fetches one template" do
      stub_request(:get, "#{base_url}/templates/1")
        .to_return(status: 200, body: JSON.generate({"id" => 1}))

      expect(described_class.find(1)).to eq({"id" => 1})
    end
  end

  describe ".create" do
    it "wraps the attributes under the template root key" do
      stub = stub_request(:post, "#{base_url}/templates")
        .with(body: JSON.generate({template: {title: "Contrat", content: "<p>x</p>"}}))
        .to_return(status: 201, body: JSON.generate({"id" => 2}))

      expect(described_class.create(title: "Contrat", content: "<p>x</p>")).to eq({"id" => 2})
      expect(stub).to have_been_requested
    end
  end

  describe ".update" do
    it "sends a PATCH with the template root key" do
      stub = stub_request(:patch, "#{base_url}/templates/2")
        .with(body: JSON.generate({template: {title: "Avenant"}}))
        .to_return(status: 200, body: JSON.generate({"id" => 2}))

      described_class.update(2, title: "Avenant")

      expect(stub).to have_been_requested
    end
  end

  describe ".destroy" do
    it "archives the template and returns an empty hash" do
      stub_request(:delete, "#{base_url}/templates/2").to_return(status: 204)

      expect(described_class.destroy(2)).to eq({})
    end
  end

  describe ".publish" do
    it "sends a PUT on the publish route" do
      stub = stub_request(:put, "#{base_url}/templates/2/publish")
        .to_return(status: 200, body: JSON.generate({"id" => 2, "published" => true}))

      expect(described_class.publish(2)).to include("published" => true)
      expect(stub).to have_been_requested
    end
  end

  describe ".unpublish" do
    it "sends a PUT on the unpublish route" do
      stub = stub_request(:put, "#{base_url}/templates/2/unpublish")
        .to_return(status: 200, body: JSON.generate({"id" => 2, "published" => false}))

      described_class.unpublish(2)

      expect(stub).to have_been_requested
    end
  end
end
