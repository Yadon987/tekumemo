class Achievement < ApplicationRecord
  has_many :user_achievements, dependent: :destroy
  has_many :users, through: :user_achievements

  validates :name, presence: true
  validates :description, presence: true
  validates :condition_type, presence: true
  validates :condition_value, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :icon_name, presence: true

  enum :condition_type, {
    total_steps: 0,      # 累計歩数
    total_distance: 1,   # 累計距離
    login_streak: 2,     # 連続ログイン
    post_count: 3        # 投稿数
  }
end
