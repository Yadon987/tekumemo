FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "tester#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    name { "テストユーザー" }
    target_distance { 5000 } # 5km
  end
end
