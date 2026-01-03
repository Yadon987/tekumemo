FactoryBot.define do
  factory :notification do
    association :user
    announcement { nil } # デフォルトはnil
    read_at { nil }
  end
end
