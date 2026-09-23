FactoryBot.define do
  factory :salary_record do
    employee
    amount { 90_000 }
    currency { "USD" }
    effective_date { Date.new(2022, 1, 15) }
    reason { "Initial offer" }
  end
end
