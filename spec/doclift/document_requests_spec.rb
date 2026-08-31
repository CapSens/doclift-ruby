RSpec.describe Doclift::DocumentRequests do
  let(:base_url) { "https://app.doclift.io/api/v1" }

  before do
    Doclift.configure { |config| config.api_key = "test_api_key" }
  end

  describe ".list" do
    it "tolerates the empty listing that carries no pagination headers", :aggregate_failures do
      stub_request(:get, "#{base_url}/document_requests")
        .to_return(status: 200, body: JSON.generate([]))

      page = described_class.list

      expect(page.items).to eq([])
      expect(page.next_page?).to be(false)
    end
  end

  describe ".find" do
    it "fetches one document request" do
      stub_request(:get, "#{base_url}/document_requests/991")
        .to_return(status: 200, body: JSON.generate({"id" => 991}))

      expect(described_class.find(991)).to eq({"id" => 991})
    end
  end

  describe ".create" do
    it "builds the full payload with priority and tag" do
      stub = stub_request(:post, "#{base_url}/document_requests")
        .with(
          body: JSON.generate({
            document_request: {
              type: "asynchrone",
              tag: "batch-2026-08",
              priority: "default",
              document_generations: [{template_id: 124, variables: {nom: "Dupont"}}],
            },
          }),
        )
        .to_return(status: 200, body: JSON.generate({"id" => 992, "status" => "in_progress"}))

      response = described_class.create(
        type: described_class::TYPE_ASYNCHRONOUS,
        generations: [{template_id: 124, variables: {nom: "Dupont"}}],
        priority: "default",
        tag: "batch-2026-08",
      )

      expect(response).to include("status" => "in_progress")
      expect(stub).to have_been_requested
    end

    it "omits the optional keys left at nil" do
      stub = stub_request(:post, "#{base_url}/document_requests")
        .with(
          body: JSON.generate({
            document_request: {
              type: "synchrone",
              document_generations: [{template_id: 124, variables: {}}],
            },
          }),
        )
        .to_return(status: 200, body: JSON.generate({"id" => 991}))

      described_class.create(
        type: described_class::TYPE_SYNCHRONOUS,
        generations: [{template_id: 124, variables: {}}],
      )

      expect(stub).to have_been_requested
    end

    it "raises a ValidationError carrying the invalid variables", :aggregate_failures do
      stub_request(:post, "#{base_url}/document_requests").to_return(
        status: 422,
        body: JSON.generate({
          "error" => "Les valeurs fournies pour certaines variables ne sont pas valides",
          "invalid_variables" => [
            {"field" => "civilite", "value" => "Mx", "allowed_values" => ["M", "Mme"]},
          ],
        }),
      )

      expect do
        described_class.create(type: "synchrone", generations: [{template_id: 1, variables: {}}])
      end.to raise_error(Doclift::ValidationError) do |error|
        expect(error.invalid_variables).to contain_exactly(hash_including("field" => "civilite"))
      end
    end
  end

  describe "response readers" do
    let(:response) do
      {
        "id" => 991,
        "type" => "synchrone",
        "documents_generations" => [
          {
            "generation_status" => "success",
            "generation_error" => nil,
            "file" => {"filename" => "doc.pdf", "url" => "https://s3.example/doc.pdf", "size" => 84_213},
          },
        ],
      }
    end

    it "digs the file URL out of the response" do
      expect(described_class.file_url(response)).to eq("https://s3.example/doc.pdf")
    end

    it "returns nil rather than raise when the generation is absent" do
      expect(described_class.file_url(response, index: 4)).to be_nil
    end

    it "reads the generation status" do
      expect(described_class.generation_status(response)).to eq("success")
    end

    it "reads the generation error" do
      expect(described_class.generation_error(response)).to be_nil
    end

    it "reads the request status of an asynchronous response" do
      expect(described_class.status({"status" => "in_progress"})).to eq("in_progress")
    end
  end
end
