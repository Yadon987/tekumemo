FactoryBot.define do
  factory :reaction do
    association :user
    association :post
    stamp { :thumbs_up }
  end
end
