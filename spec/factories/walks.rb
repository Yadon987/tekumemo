FactoryBot.define do
  factory :walk do
    association :user
    walked_on { Date.current }
    duration { 30 } # 分
    distance { 2.5 } # km
    steps { 3000 }
    calories_burned { 150 }

    # 過去の日付のデータを作るためのトレイト
    trait :yesterday do
      walked_on { 1.day.ago.to_date }
    end
  end
end
