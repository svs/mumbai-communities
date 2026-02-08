FactoryBot.define do
  factory :boundary do
    association :boundable, factory: :prabhag
    geojson do
      {
        type: "Feature",
        geometry: {
          type: "Polygon",
          coordinates: [[[72.8, 19.0], [72.81, 19.0], [72.81, 19.01], [72.8, 19.01], [72.8, 19.0]]]
        },
        properties: {}
      }.to_json
    end
    source_type { "user_submission" }
    year { 2025 }
    status { "pending" }
    submitted_by { association :user }

    trait :pending do
      status { "pending" }
    end

    trait :approved do
      status { "approved" }
    end

    trait :rejected do
      status { "rejected" }
    end

    trait :canonical do
      status { "canonical" }
      is_canonical { true }
    end
  end
end
