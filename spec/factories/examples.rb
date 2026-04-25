FactoryBot.define do
  factory :example do
    association :meaning
    sentence { 'Hello, world!' }
    translation { 'こんにちは、世界！' }
    sequence(:display_order) { |n| n }
  end
end
