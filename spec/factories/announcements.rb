FactoryBot.define do
  factory :announcement do
    title { "テストお知らせ" }
    content { "これはテスト用のお知らせです。" }
    announcement_type { "info" }
    published_at { Time.current }
    expires_at { nil }
    is_published { true }
  end
end
