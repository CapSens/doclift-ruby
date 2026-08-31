RSpec.describe Doclift::Workflows::Capabilities do
  before do
    Doclift.configure { |config| config.api_key = "test_api_key" }
  end

  describe ".show" do
    it "fetches the contract manifest" do
      stub_request(:get, "https://app.doclift.io/api/v1/workflows/capabilities")
        .to_return(status: 200, body: JSON.generate({"contract_version" => "1"}))

      expect(described_class.show).to eq({"contract_version" => "1"})
    end
  end
end
