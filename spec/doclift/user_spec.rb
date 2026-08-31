RSpec.describe Doclift::User do
  before do
    Doclift.configure { |config| config.api_key = "test_api_key" }
  end

  describe ".show" do
    it "fetches the identity behind the API key" do
      stub = stub_request(:get, "https://app.doclift.io/api/v1/user")
        .to_return(status: 200, body: JSON.generate({"id" => 12, "email" => "jane@acme.io"}))

      expect(described_class.show).to include("email" => "jane@acme.io")
      expect(stub).to have_been_requested
    end
  end
end
