FactoryBot.define do
  factory :category do
    association :user
    sequence(:name) { |n| "TestCategory#{n}" }
    color { "#6C63FF" }
    icon { "home" }
  end
end
