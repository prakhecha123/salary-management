require "rails_helper"

RSpec.describe SalaryRecord, type: :model do
  describe "validations" do
    subject { build(:salary_record) }

    it { is_expected.to be_valid }

    it "rejects a zero or negative amount" do
      record = build(:salary_record, amount: 0)
      expect(record).not_to be_valid
      expect(record.errors[:amount]).to be_present

      record = build(:salary_record, amount: -100)
      expect(record).not_to be_valid
    end

    it "rejects a currency outside the supported list" do
      record = build(:salary_record, currency: "XYZ")

      expect(record).not_to be_valid
      expect(record.errors[:currency]).to be_present
    end

    it "requires an effective_date" do
      record = build(:salary_record, effective_date: nil)

      expect(record).not_to be_valid
      expect(record.errors[:effective_date]).to be_present
    end
  end

  describe "#amount_in_usd" do
    it "converts using the matching exchange rate" do
      create(:exchange_rate, :inr)
      record = build(:salary_record, amount: 100_000, currency: "INR")

      expect(record.amount_in_usd).to eq(1_200.0)
    end

    it "returns nil when no exchange rate exists for the currency" do
      record = build(:salary_record, amount: 100_000, currency: "GBP")

      expect(record.amount_in_usd).to be_nil
    end
  end
end
