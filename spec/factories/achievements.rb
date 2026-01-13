FactoryBot.define do
  factory :achievement do
    sequence(:name) { |n| "実績#{n}" }
    description { 'これはテスト用の実績です' }
    condition_type { :total_steps }
    condition_value { 1000 }
    icon_name { 'star' }
  end
end
