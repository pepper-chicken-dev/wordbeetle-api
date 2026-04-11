FactoryBot.define do
  factory :meaning do
    association :word
    definition { 'こんにちは' }
    sequence(:display_order) { |n| n }
  end
end
