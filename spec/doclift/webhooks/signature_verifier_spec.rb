RSpec.describe Doclift::Webhooks::SignatureVerifier do
  let(:secret) { "test_api_key" }
  let(:raw_body) { '{"id":1,"type":"asynchrone"}' }
  let(:valid_header) do
    "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, raw_body)}"
  end

  describe ".valid?" do
    it "accepts the signature computed with the shared secret" do
      result = described_class.valid?(raw_body: raw_body, header: valid_header, secret: secret)

      expect(result).to be(true)
    end

    it "rejects a signature computed with another secret" do
      other = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', 'other_key', raw_body)}"

      expect(described_class.valid?(raw_body: raw_body, header: other, secret: secret)).to be(false)
    end

    it "rejects a tampered body" do
      result = described_class.valid?(raw_body: "#{raw_body} ", header: valid_header, secret: secret)

      expect(result).to be(false)
    end

    it "rejects a header of a different length instead of raising" do
      result = described_class.valid?(raw_body: raw_body, header: "sha256=abc", secret: secret)

      expect(result).to be(false)
    end

    it "rejects a missing header" do
      expect(described_class.valid?(raw_body: raw_body, header: nil, secret: secret)).to be(false)
    end

    it "rejects an empty secret" do
      expect(described_class.valid?(raw_body: raw_body, header: valid_header, secret: "")).to be(false)
    end
  end
end
