FactoryBot.define do
  factory :meaning do
    association :word
    content { "こんにちは" }
    sequence(:display_order) { |n| n }
  end
end
