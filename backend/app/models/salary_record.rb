class SalaryRecord < ApplicationRecord
  belongs_to :employee

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, inclusion: { in: OrganizationReferenceData::CURRENCIES }
  validates :effective_date, presence: true

  def amount_in_usd
    ExchangeRate.convert_to_usd(amount, currency)
  end
end
