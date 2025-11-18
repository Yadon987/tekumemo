class Walk < ApplicationRecord
  # ユーザーとの関連付け（1人のユーザーは複数の散歩記録を持つ）
  belongs_to :user

  # バリデーション（入力チェック）
  # 散歩日は必須項目
  validates :walked_on, presence: true

  # 散歩時間は必須で、0以上の整数のみ許可
  validates :duration, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  # 距離は必須で、0以上の数値のみ許可
  validates :distance, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # 場所は任意項目（バリデーションなし）

  # デフォルトのソート順（新しい日付順）
  # 一覧表示時に自動的に日付順でソートされる
  default_scope { order(walked_on: :desc) }
end
