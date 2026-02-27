FactoryBot.define do
  factory :setting do
    association :user
    hard_interval { 1.day }
    uncertain_interval { 3.days }
    easy_interval { 7.days }
  end
end
