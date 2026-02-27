FactoryBot.define do
  factory :example do
    association :word
    sentence { "Hello, world!" }
    translation { "こんにちは、世界！" }
    sequence(:display_order) { |n| n }
  end
end
