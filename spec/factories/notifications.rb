FactoryBot.define do
  factory :notification do
    association :user
    association :announcement
    read_at { nil }
  end
end
