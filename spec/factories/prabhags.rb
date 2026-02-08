FactoryBot.define do
  factory :prabhag do
    sequence(:number) { |n| n + 1000 }
    name { "Test Prabhag #{number}" }
    ward_code { "TEST1" }
    sequence(:pdf_url) { |n| "https://example.com/prabhag_#{n}.pdf" }
    status { "available" }

    trait :submitted do
      status { "submitted" }
      assigned_to { association :user }
    end

    trait :approved do
      status { "approved" }
      assigned_to { association :user }
    end

    trait :rejected do
      status { "rejected" }
      assigned_to { nil }
    end

    trait :with_pending_boundary do
      after(:create) do |prabhag|
        create(:boundary, :pending, boundable: prabhag)
      end
    end

    trait :with_approved_boundary do
      after(:create) do |prabhag|
        create(:boundary, :approved, boundable: prabhag)
      end
    end
  end
end
