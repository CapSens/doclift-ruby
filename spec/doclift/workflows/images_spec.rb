RSpec.describe Doclift::Workflows::Images do
  let(:base_url) { "https://app.doclift.io/api/v1/workflows/templates/124/images" }
  let(:token) { "aB3xQ9tUvWxYz01234567890abcdefgh" }

  before do
    Doclift.configure { |config| config.api_key = "test_api_key" }
  end

  describe ".list" do
    it "returns the raw, unpaginated array" do
      stub_request(:get, base_url)
        .to_return(status: 200, body: JSON.generate([{"id" => 41, "token" => token}]))

      expect(described_class.list(template_id: 124)).to eq([{"id" => 41, "token" => token}])
    end
  end

  describe ".find" do
    it "addresses the image by its token" do
      stub = stub_request(:get, "#{base_url}/#{token}")
        .to_return(status: 200, body: JSON.generate({"token" => token}))

      expect(described_class.find(template_id: 124, token: token)).to eq({"token" => token})
      expect(stub).to have_been_requested
    end
  end

  describe ".create" do
    it "sends the base64 upload under the image root key" do
      stub = stub_request(:post, base_url)
        .with(body: JSON.generate({
          image: {filename: "logo.png", content_type: "image/png", data: "aVZCT1J3MEtHZ28="},
        }))
        .to_return(status: 201, body: JSON.generate({"token" => token, "url" => "/workflows/images/#{token}"}))

      response = described_class.create(
        template_id: 124,
        filename: "logo.png",
        content_type: "image/png",
        data: "aVZCT1J3MEtHZ28=",
      )

      expect(response).to include("url" => "/workflows/images/#{token}")
      expect(stub).to have_been_requested
    end
  end

  describe ".destroy" do
    it "deletes by token and returns an empty hash" do
      stub_request(:delete, "#{base_url}/#{token}").to_return(status: 204)

      expect(described_class.destroy(template_id: 124, token: token)).to eq({})
    end
  end
end
