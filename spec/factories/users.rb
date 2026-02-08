FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "factoryuser#{n + 10000}@example.com" }
    password { "password123" }
    sequence(:name) { |n| "Factory User #{n}" }
    admin { false }

    trait :admin do
      admin { true }
      sequence(:email) { |n| "factoryadmin#{n + 10000}@example.com" }
      sequence(:name) { |n| "Factory Admin #{n}" }
    end
  end
end
