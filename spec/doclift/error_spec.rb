RSpec.describe Doclift::ApiError do
  describe ".from_response" do
    {
      400 => Doclift::BadRequestError,
      401 => Doclift::BadRequestError,
      403 => Doclift::AuthenticationError,
      404 => Doclift::NotFoundError,
      409 => Doclift::ConflictError,
      422 => Doclift::ValidationError,
      500 => Doclift::ServerError,
      503 => Doclift::ServerError,
    }.each do |status, error_class|
      it "maps #{status} to #{error_class}" do
        error = described_class.from_response(status, {"error" => "boom"})

        expect(error.class).to eq(error_class)
      end
    end

    it "keeps unmapped statuses as a bare ApiError" do
      error = described_class.from_response(418, {"error" => "boom"})

      expect(error.class).to eq(described_class)
    end

    it "reads the message from the singular error key", :aggregate_failures do
      error = described_class.from_response(422, {"error" => "Le modèle n'existe pas"})

      expect(error.message).to eq("Le modèle n'existe pas")
      expect(error.status).to eq(422)
      expect(error.details).to eq({"error" => "Le modèle n'existe pas"})
    end

    it "joins the plural errors key used by the malformed-JSON handler" do
      error = described_class.from_response(401, {"errors" => ["bad", "json"]})

      expect(error.message).to eq("bad, json")
    end

    it "ignores an empty errors array" do
      error = described_class.from_response(401, {"errors" => []})

      expect(error.message).to eq("Doclift API error 401")
    end

    it "ignores a non-string error value" do
      error = described_class.from_response(422, {"error" => {"nested" => true}})

      expect(error.message).to eq("Doclift API error 422")
    end

    it "ignores an empty error string" do
      error = described_class.from_response(422, {"error" => ""})

      expect(error.message).to eq("Doclift API error 422")
    end

    it "falls back to a generic message when the body is not a hash", :aggregate_failures do
      error = described_class.from_response(500, ["unexpected"])

      expect(error.message).to eq("Doclift API error 500")
      expect(error.details).to eq({})
    end
  end
end

RSpec.describe Doclift::ValidationError do
  describe "#invalid_variables" do
    it "exposes the invalid_variables array from the body" do
      error = Doclift::ApiError.from_response(
        422,
        {
          "error" => "Variables invalides",
          "invalid_variables" => [
            {"field" => "civility", "value" => "X", "allowed_values" => ["M", "Mme"]},
          ],
        },
      )

      expect(error.invalid_variables)
        .to contain_exactly(hash_including("field" => "civility"))
    end

    it "returns an empty array when the key is absent or not an array" do
      error = Doclift::ApiError.from_response(422, {"error" => "boom"})

      expect(error.invalid_variables).to eq([])
    end
  end
end

RSpec.describe Doclift::ConnectionError do
  it "keeps the underlying network error class", :aggregate_failures do
    error = described_class.new("boom", cause_class: Net::ReadTimeout)

    expect(error.message).to eq("boom")
    expect(error.cause_class).to eq(Net::ReadTimeout)
  end

  it "defaults cause_class to nil" do
    expect(described_class.new("boom").cause_class).to be_nil
  end
end
