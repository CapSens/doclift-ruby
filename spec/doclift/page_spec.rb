RSpec.describe Doclift::Page do
  let(:headers) do
    {
      "results" => "61",
      "results_per_page" => "30",
      "current_page" => "2",
      "pages_count" => "3",
    }
  end

  it "enumerates its items" do
    page = described_class.new([{"id" => 1}, {"id" => 2}], headers)

    expect(page.map { |item| item["id"] }).to eq([1, 2])
  end

  it "exposes the pagination metadata read from the headers", :aggregate_failures do
    page = described_class.new([], headers)

    expect(page.total_results).to eq(61)
    expect(page.per_page).to eq(30)
    expect(page.current_page).to eq(2)
    expect(page.pages_count).to eq(3)
  end

  it "returns nil metadata when the headers are absent", :aggregate_failures do
    page = described_class.new([{"id" => 1}])

    expect(page.total_results).to be_nil
    expect(page.per_page).to be_nil
    expect(page.current_page).to be_nil
    expect(page.pages_count).to be_nil
  end

  it "returns nil rather than raise on a non-numeric header" do
    page = described_class.new([], headers.merge("results" => "not-a-number"))

    expect(page.total_results).to be_nil
  end

  it "tolerates a non-array body by exposing no items" do
    page = described_class.new({"error" => "unexpected"}, headers)

    expect(page.items).to eq([])
  end

  describe "#next_page?" do
    it "is true when pages remain" do
      expect(described_class.new([], headers).next_page?).to be(true)
    end

    it "is false on the last page" do
      page = described_class.new([], headers.merge("current_page" => "3"))

      expect(page.next_page?).to be(false)
    end

    it "is false when the current page is unknown" do
      page = described_class.new([], headers.except("current_page"))

      expect(page.next_page?).to be(false)
    end

    it "is false when the pages count is unknown" do
      page = described_class.new([], headers.except("pages_count"))

      expect(page.next_page?).to be(false)
    end
  end
end
