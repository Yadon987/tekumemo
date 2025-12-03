FactoryBot.define do
  factory :post do
    user { nil }
    walk { nil }
    body { "MyText" }
    weather { 1 }
    feeling { 1 }
  end
end
