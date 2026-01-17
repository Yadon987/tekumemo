FactoryBot.define do
  factory :walk do
    association :user
    walked_on { Date.current }
    minutes { 30 } # 分
    kilometers { 2.5 } # km
    steps { 3000 }
    calories { 150 }

    # 過去の日付のデータを作るためのトレイト
    trait :yesterday do
      walked_on { 1.day.ago.to_date }
    end
  end
end
