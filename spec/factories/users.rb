FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "tester#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    name { 'テストユーザー' }
    goal_meters { 5000 } # 5km

    trait :general do
      role { :general }
    end

    trait :admin do
      role { :admin }
    end
  end
end
