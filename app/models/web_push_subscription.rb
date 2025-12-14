class WebPushSubscription < ApplicationRecord
  belongs_to :user

  # バリデーション
  validates :endpoint, presence: true, uniqueness: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "は有効なURLである必要があります" }
  validates :p256dh, presence: true
  validates :auth_key, presence: true
end
