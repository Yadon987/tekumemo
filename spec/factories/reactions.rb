FactoryBot.define do
  factory :reaction do
    association :user
    association :post
    kind { :thumbs_up }
  end
end
