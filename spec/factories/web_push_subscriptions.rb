FactoryBot.define do
  factory :web_push_subscription do
    association :user
    endpoint { "https://fcm.googleapis.com/fcm/send/#{SecureRandom.hex}" }
    p256dh { SecureRandom.base64(65) }
    auth_key { SecureRandom.base64(16) }
    user_agent { "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" }
  end
end
