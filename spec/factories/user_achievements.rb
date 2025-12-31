FactoryBot.define do
  factory :user_achievement do
    association :user
    association :achievement
  end
end
