FactoryBot.define do
  factory :wordbook do
    association :user
    title { "My Wordbook" }
  end
end
