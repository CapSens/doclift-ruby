RSpec.describe Doclift do
  it "has a version number" do
    expect(Doclift::VERSION).not_to be_nil
  end

  describe ".configuration" do
    it "memoizes a single Configuration instance" do
      expect(described_class.configuration).to equal(described_class.configuration)
    end
  end

  describe ".configure" do
    it "yields the global configuration" do
      described_class.configure { |config| config.api_key = "configured_key" }

      expect(described_class.configuration.api_key).to eq("configured_key")
    end
  end

  describe ".client" do
    it "memoizes a single Client instance" do
      expect(described_class.client).to equal(described_class.client)
    end
  end

  describe ".reset!" do
    it "drops the memoized configuration and client", :aggregate_failures do
      configuration = described_class.configuration
      client = described_class.client

      described_class.reset!

      expect(described_class.configuration).not_to equal(configuration)
      expect(described_class.client).not_to equal(client)
    end
  end
end
