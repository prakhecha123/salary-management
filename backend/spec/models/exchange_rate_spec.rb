require "rails_helper"

RSpec.describe ExchangeRate, type: :model do
  describe "validations" do
    subject { build(:exchange_rate) }

    it { is_expected.to be_valid }

    it "requires a unique currency" do
      create(:exchange_rate, currency: "USD")
      duplicate = build(:exchange_rate, currency: "USD")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:currency]).to be_present
    end

    it "rejects a currency outside the supported list" do
      rate = build(:exchange_rate, currency: "XYZ")

      expect(rate).not_to be_valid
      expect(rate.errors[:currency]).to be_present
    end

    it "rejects a zero or negative rate" do
      rate = build(:exchange_rate, rate_to_usd: 0)

      expect(rate).not_to be_valid
      expect(rate.errors[:rate_to_usd]).to be_present
    end
  end

  describe ".convert_to_usd" do
    it "multiplies the amount by the stored rate, rounded to cents" do
      create(:exchange_rate, :inr)

      expect(ExchangeRate.convert_to_usd(83_333, "INR")).to eq(999.996.round(2))
    end

    it "returns nil when there is no rate for the currency" do
      expect(ExchangeRate.convert_to_usd(100, "GBP")).to be_nil
    end
  end
end
