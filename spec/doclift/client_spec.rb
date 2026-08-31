RSpec.describe Doclift::Client do
  let(:base_url) { "https://app.doclift.io/api/v1" }

  before do
    Doclift.configure { |config| config.api_key = "test_api_key" }
  end

  describe "#get" do
    it "sends the authentication and content headers", :aggregate_failures do
      stub = stub_request(:get, "#{base_url}/user")
        .with(
          headers: {
            "X-Api-Key" => "test_api_key",
            "Accept" => "application/json",
            "Content-Type" => "application/json",
            "User-Agent" => "doclift-ruby/#{Doclift::VERSION}",
          },
        )
        .to_return(status: 200, body: JSON.generate({"id" => 1}))

      expect(Doclift.client.get("/user")).to eq({"id" => 1})
      expect(stub).to have_been_requested
    end

    it "accepts a path without a leading slash" do
      stub = stub_request(:get, "#{base_url}/user")
        .to_return(status: 200, body: JSON.generate({}))

      Doclift.client.get("user")

      expect(stub).to have_been_requested
    end

    it "appends query parameters, dropping the nil ones" do
      stub = stub_request(:get, "#{base_url}/templates?page=2")
        .to_return(status: 200, body: JSON.generate([]))

      Doclift.client.get("/templates", params: {page: 2, tag: nil})

      expect(stub).to have_been_requested
    end

    it "returns an empty hash for an empty body" do
      stub_request(:get, "#{base_url}/user").to_return(status: 200, body: "")

      expect(Doclift.client.get("/user")).to eq({})
    end

    it "wraps an unparseable body rather than raise" do
      stub_request(:get, "#{base_url}/user")
        .to_return(status: 200, body: "<html>oops</html>")

      expect(Doclift.client.get("/user")).to eq({"raw_body" => "<html>oops</html>"})
    end

    it "reaches a non-standard host, port and scheme from the configuration" do
      Doclift.configure { |config| config.api_url = "http://localhost:3000/api/v1" }
      stub = stub_request(:get, "http://localhost:3000/api/v1/user")
        .to_return(status: 200, body: JSON.generate({}))

      Doclift.client.get("/user")

      expect(stub).to have_been_requested
    end
  end

  describe "#get_page" do
    it "builds a Page from the body and the pagination headers", :aggregate_failures do
      stub_request(:get, "#{base_url}/templates?page=2").to_return(
        status: 200,
        body: JSON.generate([{"id" => 1}]),
        headers: {
          "results" => "61",
          "results_per_page" => "30",
          "current_page" => "2",
          "pages_count" => "3",
        },
      )

      page = Doclift.client.get_page("/templates", params: {page: 2})

      expect(page.items).to eq([{"id" => 1}])
      expect(page.total_results).to eq(61)
      expect(page.current_page).to eq(2)
      expect(page.pages_count).to eq(3)
      expect(page.next_page?).to be(true)
    end

    it "tolerates the empty listing that comes without pagination headers", :aggregate_failures do
      stub_request(:get, "#{base_url}/document_requests")
        .to_return(status: 200, body: JSON.generate([]))

      page = Doclift.client.get_page("/document_requests")

      expect(page.items).to eq([])
      expect(page.current_page).to be_nil
      expect(page.next_page?).to be(false)
    end
  end

  describe "#post_json" do
    it "serializes the body as JSON" do
      stub = stub_request(:post, "#{base_url}/document_requests")
        .with(body: JSON.generate({document_request: {type: "synchrone"}}))
        .to_return(status: 200, body: JSON.generate({"id" => 1}))

      response = Doclift.client.post_json("/document_requests", {document_request: {type: "synchrone"}})

      expect(response).to eq({"id" => 1})
      expect(stub).to have_been_requested
    end
  end

  describe "#patch_json" do
    it "sends a PATCH with a JSON body" do
      stub = stub_request(:patch, "#{base_url}/templates/1")
        .with(body: JSON.generate({template: {title: "New"}}))
        .to_return(status: 200, body: JSON.generate({"id" => 1}))

      Doclift.client.patch_json("/templates/1", {template: {title: "New"}})

      expect(stub).to have_been_requested
    end
  end

  describe "#put_json" do
    it "sends a PUT with a JSON body" do
      stub = stub_request(:put, "#{base_url}/templates/1/publish")
        .with(body: JSON.generate({}))
        .to_return(status: 200, body: JSON.generate({"id" => 1}))

      Doclift.client.put_json("/templates/1/publish", {})

      expect(stub).to have_been_requested
    end
  end

  describe "#delete" do
    it "returns an empty hash for a 204 without body" do
      stub_request(:delete, "#{base_url}/templates/1").to_return(status: 204)

      expect(Doclift.client.delete("/templates/1")).to eq({})
    end
  end

  describe "error handling" do
    it "raises the mapped error with the parsed body", :aggregate_failures do
      stub_request(:get, "#{base_url}/templates/99")
        .to_return(status: 404, body: JSON.generate({"error" => "Template not found"}))

      expect { Doclift.client.get("/templates/99") }.to raise_error(Doclift::NotFoundError) do |error|
        expect(error.status).to eq(404)
        expect(error.message).to eq("Template not found")
      end
    end

    it "wraps a timeout in a ConnectionError", :aggregate_failures do
      stub_request(:get, "#{base_url}/user").to_timeout

      expect { Doclift.client.get("/user") }.to raise_error(Doclift::ConnectionError) do |error|
        expect(error.message).to include("Doclift connection error")
      end
    end

    it "wraps a refused connection in a ConnectionError" do
      stub_request(:get, "#{base_url}/user").to_raise(Errno::ECONNREFUSED)

      expect { Doclift.client.get("/user") }.to raise_error(Doclift::ConnectionError) do |error|
        expect(error.cause_class).to eq(Errno::ECONNREFUSED)
      end
    end

    it "wraps a write timeout in a ConnectionError" do
      stub_request(:post, "#{base_url}/document_requests").to_raise(Net::WriteTimeout)

      expect { Doclift.client.post_json("/document_requests", {}) }
        .to raise_error(Doclift::ConnectionError) do |error|
          expect(error.cause_class).to eq(Net::WriteTimeout)
        end
    end

    it "raises a ConfigurationError before any request when the api_key is missing" do
      Doclift.reset!

      expect { Doclift.client.get("/user") }
        .to raise_error(Doclift::ConfigurationError, /api_key/)
    end
  end

  describe "logging" do
    it "logs the request at debug level" do
      logs = StringIO.new
      Doclift.configure { |config| config.logger = Logger.new(logs) }
      stub_request(:get, "#{base_url}/user").to_return(status: 200, body: "")

      Doclift.client.get("/user")

      expect(logs.string).to include("[Doclift] GET")
    end
  end
end
