class Walk < ApplicationRecord
  # ユーザーとの関連付け（1人のユーザーは複数の散歩記録を持つ）
  belongs_to :user

  # バリデーション（入力チェック）

  # 散歩日は必須項目
  # ▼ 追加: 同じユーザーが同じ日に複数の記録を作成できないようにする
  validates :walked_on, presence: true
  validates :walked_on, uniqueness: { scope: :user_id, message: "の記録は既に存在します。同じ日付の記録を編集、もしくは削除してください。" }

  # 距離と時間を必須に ▼▼▼
  # 散歩時間は任意項目で、入力された場合は0以上の整数のみ許可
  validates :duration, presence: true, numericality: { greater_than: 0, only_integer: true }

  # 距離は任意項目で、入力された場合は0以上の数値のみ許可（上限50km）
  validates :distance, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 50 }

  # 歩数は任意項目で、入力された場合は0以上の整数のみ許可
  validates :steps, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true

  # 消費カロリーは任意項目で、入力された場合は0以上の整数のみ許可
  validates :calories_burned, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true

  # 場所とメモはバリデーションなし（完全に任意）

  # 時間帯 (0:早朝, 1:日中, 2:夕方, 3:夜間)
  enum :time_of_day, {
    early_morning: 0, # 04:00 - 08:59
    day: 1,           # 09:00 - 15:59
    evening: 2,       # 16:00 - 18:59
    night: 3          # 19:00 - 03:59
  }, prefix: true

  # ==========================================
  # スコープ（データの絞り込みや並び替え）
  # ==========================================

  # 新しい日付順に並び替えるスコープ
  # (default_scopeは予期せぬバグの原因になりやすいため、名前付きスコープを使用)
  scope :recent, -> { order(walked_on: :desc) }

  # コールバック
  before_save :set_time_of_day_from_created_at

  # Google Fitのデータをマージする
  # 既存の値より大きい場合のみ更新する
  def merge_google_fit_data(data)
    if new_record?
      self.distance = data[:distance]
      self.steps = data[:steps]
      self.calories_burned = data[:calories]
      self.duration = data[:duration] if data[:duration]
    else
      self.distance = data[:distance] if distance.to_f < data[:distance]
      self.steps = data[:steps] if steps.to_i < data[:steps]
      self.calories_burned = data[:calories] if calories_burned.to_i < data[:calories]
      self.duration = data[:duration] if data[:duration] && duration.to_i < data[:duration].to_i
    end

    # 時間帯の設定（未設定の場合のみ）
    if time_of_day.blank? && data[:start_time]
      set_time_of_day_from_hour(data[:start_time].hour)
    elsif time_of_day.blank?
      self.time_of_day = :day # デフォルト
    end
  end

  private

  def set_time_of_day_from_created_at
    return if time_of_day.present?

    # created_atが未設定の場合は現在時刻を使用
    target_time = created_at || Time.current
    hour = target_time.hour

    self.time_of_day = case hour
    when 4..8 then :early_morning
    when 9..15 then :day
    when 16..18 then :evening
    else :night
    end
  end



  private

  def set_time_of_day_from_hour(hour)
    self.time_of_day = case hour
    when 4..8 then :early_morning
    when 9..15 then :day
    when 16..18 then :evening
    else :night
    end
  end
end
