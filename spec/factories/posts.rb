FactoryBot.define do
  factory :post do
    association :user
    content { '今日はいい天気で散歩日和でした！' }
    weather { :sunny }
    feeling { :great }
  end
end
