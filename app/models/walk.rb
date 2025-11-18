class Walk < ApplicationRecord
  # ユーザーとの関連付け（1人のユーザーは複数の散歩記録を持つ）
  belongs_to :user

  # バリデーション（入力チェック）
  # 散歩日は必須項目
  validates :walked_on, presence: true

  # 散歩時間は任意項目で、入力された場合は0以上の整数のみ許可
  validates :duration, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true

  # 距離は任意項目で、入力された場合は0以上の数値のみ許可
  validates :distance, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # 歩数は任意項目で、入力された場合は0以上の整数のみ許可
  validates :steps, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true

  # 消費カロリーは任意項目で、入力された場合は0以上の整数のみ許可
  validates :calories_burned, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true

  # 場所は任意項目（バリデーションなし）
  # メモは任意項目（バリデーションなし）

  # デフォルトのソート順（新しい日付順）
  # 一覧表示時に自動的に日付順でソートされる
  default_scope { order(walked_on: :desc) }
end
