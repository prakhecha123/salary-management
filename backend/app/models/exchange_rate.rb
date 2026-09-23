class ExchangeRate < ApplicationRecord
  validates :currency, presence: true, uniqueness: true,
    inclusion: { in: OrganizationReferenceData::CURRENCIES }
  validates :rate_to_usd, presence: true, numericality: { greater_than: 0 }

  def self.convert_to_usd(amount, currency)
    rate = find_by(currency: currency)&.rate_to_usd
    return nil unless rate

    (amount * rate).round(2)
  end
end
