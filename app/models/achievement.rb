class Achievement < ApplicationRecord
  has_many :user_achievements, dependent: :destroy
  has_many :users, through: :user_achievements

  validates :title, presence: true
  validates :flavor_text, presence: true
  validates :metric, presence: true
  validates :requirement, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :badge_key, presence: true

  enum :metric, {
    total_steps: 0,      # 累計歩数
    total_distance: 1,   # 累計距離
    login_streak: 2,     # 連続ログイン
    post_count: 3        # 投稿数
  }
end
