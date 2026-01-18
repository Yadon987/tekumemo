FactoryBot.define do
  factory :reminder_log do
    association :user
    announcement { nil } # デフォルトはnil
    read_at { nil }
  end
end
