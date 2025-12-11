FactoryBot.define do
  factory :announcement do
    title { "MyString" }
    content { "MyText" }
    announcement_type { "MyString" }
    published_at { "2025-12-11 17:39:39" }
    expires_at { "2025-12-11 17:39:39" }
    is_published { false }
    priority { 1 }
  end
end
