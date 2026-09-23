FactoryBot.define do
  factory :exchange_rate do
    currency { "USD" }
    rate_to_usd { 1.0 }

    trait :inr do
      currency { "INR" }
      rate_to_usd { 0.012 }
    end

    trait :gbp do
      currency { "GBP" }
      rate_to_usd { 1.27 }
    end
  end
end
