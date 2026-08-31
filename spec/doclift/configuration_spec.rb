RSpec.describe Doclift::Configuration do
  describe "#initialize" do
    it "applies the documented defaults", :aggregate_failures do
      configuration = described_class.new

      expect(configuration.api_url).to eq("https://app.doclift.io/api/v1")
      expect(configuration.api_key).to be_nil
      expect(configuration.open_timeout).to eq(5)
      expect(configuration.read_timeout).to eq(120)
      expect(configuration.write_timeout).to eq(60)
      expect(configuration.logger).to be_a(Logger)
    end
  end

  describe "#validate!" do
    it "raises a ConfigurationError when the api_key is missing" do
      configuration = described_class.new

      expect { configuration.validate! }
        .to raise_error(Doclift::ConfigurationError, /api_key/)
    end

    it "raises a ConfigurationError when the api_key is blank" do
      configuration = described_class.new
      configuration.api_key = "   "

      expect { configuration.validate! }
        .to raise_error(Doclift::ConfigurationError, /api_key/)
    end

    it "returns nil when the api_key is present" do
      configuration = described_class.new
      configuration.api_key = "test_api_key"

      expect(configuration.validate!).to be_nil
    end
  end

  describe "#api_uri" do
    it "parses and memoizes the api_url", :aggregate_failures do
      configuration = described_class.new

      expect(configuration.api_uri).to eq(URI.parse("https://app.doclift.io/api/v1"))
      expect(configuration.api_uri).to equal(configuration.api_uri)
    end

    it "recomputes after the api_url is reassigned" do
      configuration = described_class.new
      configuration.api_uri

      configuration.api_url = "http://localhost:4000/api/v1"

      expect(configuration.api_uri).to eq(URI.parse("http://localhost:4000/api/v1"))
    end
  end
end
