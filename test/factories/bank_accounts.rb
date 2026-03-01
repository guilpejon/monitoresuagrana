FactoryBot.define do
  factory :bank_account do
    association :user
    name { Faker::Bank.name }
    bank_name { Faker::Company.name }
    account_type { "checking" }
    balance { 1000.0 }
    interest_rate { 5.0 }
    currency { "BRL" }
    color { "#6C63FF" }
    rate_type { "fixed" }
    cdi_multiplier { 100.0 }

    trait :cdi do
      rate_type { "cdi_percentage" }
      cdi_multiplier { 120.0 }
      interest_rate { 0 }
    end
  end
end
