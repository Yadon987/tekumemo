FactoryBot.define do
  factory :web_push_subscription do
    user { nil }
    endpoint { "MyString" }
    p256dh { "MyString" }
    auth_key { "MyString" }
    user_agent { "MyString" }
  end
end
