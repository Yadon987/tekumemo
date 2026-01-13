FactoryBot.define do
  factory :post do
    association :user
    body { '今日はいい天気で散歩日和でした！' }
    weather { :sunny }
    feeling { :great }
  end
end
