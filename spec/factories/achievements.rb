FactoryBot.define do
  factory :achievement do
    sequence(:title) { |n| "実績#{n}" }
    flavor_text { 'これはテスト用の実績です' }
    metric { :total_steps }
    requirement { 1000 }
    badge_key { 'star' }
  end
end
