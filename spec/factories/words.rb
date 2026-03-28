FactoryBot.define do
  factory :word do
    association :wordbook
    spelling { 'hello' }
    status { 'not_studied' }
  end
end
