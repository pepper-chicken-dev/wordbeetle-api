FactoryBot.define do
  factory :user do
    sequence(:provider_uid) { |n| "uid_#{n}" }
    provider { "google" }
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "Test User" }

    trait :guest do
      provider { "guest" }
      provider_uid { nil }
      email { nil }
      name { nil }
      guest_expires_at { 30.days.from_now }
    end
  end
end
