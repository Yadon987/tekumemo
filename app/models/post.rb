class Post < ApplicationRecord
  # アソシエーション（他のモデルとの関連付け）
  belongs_to :user  # 投稿は必ず1人のユーザー
  belongs_to :walk, optional: true  # 散歩記録の紐付けは任意
  has_many :reactions, dependent: :destroy

  # バリデーション
  validates :body, length: { maximum: 200 }, allow_blank: true
  # enumを使用しているため、数値範囲のinclusionバリデーションは不要（削除）

  # カスタムバリデーション: body、weather、feeling、walkのいずれか1つは必須
  validate :must_have_content

  # enum（整数値に名前をつける機能）
  enum :weather, {
    sunny: 0,      # ☀️ 晴れ
    cloudy: 1,     # ☁️ 曇り
    rainy: 2,      # 🌧️ 雨
    snowy: 3,      # ⛄ 雪
    stormy: 4      # ⚡ 嵐
  }, prefix: true

  enum :feeling, {
    great: 0,      # 😊 最高
    good: 1,       # 🙂 良い
    normal: 2,     # 😐 普通
    tired: 3,      # 😮‍💨 疲れた
    exhausted: 4   # 😫 ヘトヘト
  }, prefix: true

  # スコープ（よく使うクエリに名前をつける）
  scope :recent, -> { order(created_at: :desc) }  # 新しい順に並べる
  scope :with_walk, -> { where.not(walk_id: nil) }  # 散歩記録が紐付いている投稿のみ取得
  scope :with_associations, -> { includes(:user, :walk, :reactions) }  # N+1対策

  # 特定ユーザーがつけた全リアクションを取得（複数対応）
  def user_reactions(user)
    return [] unless user  # ログインしていない場合は空配列
    reactions.where(user: user)
  end

  # 特定ユーザーが特定のリアクションをつけているか判定
  def reacted_by?(user, kind)
    return false unless user
    reactions.exists?(user: user, kind: kind)
  end

  # 特定ユーザーがこの投稿に何らかのリアクションをつけているか判定
  def reacted_by_user?(user)
    return false unless user
    reactions.exists?(user: user)
  end

  # 天気の絵文字を返す
  def weather_emoji
    return nil unless weather
    case weather.to_sym
    when :sunny then "☀️"
    when :cloudy then "☁️"
    when :rainy then "🌧️"
    when :snowy then "⛄"
    when :stormy then "⚡"
    end
  end

  # 気分の絵文字を返す
  def feeling_emoji
    return nil unless feeling
    case feeling.to_sym
    when :great then "😆"
    when :good then "😄"
    when :normal then "🙂"
    when :tired then "😮‍💨"
    when :exhausted then "😫"
    end
  end

  # 天気の日本語ラベルを返す
  def weather_label
    return nil unless weather
    case weather.to_sym
    when :sunny then "晴れ"
    when :cloudy then "曇り"
    when :rainy then "雨"
    when :snowy then "雪"
    when :stormy then "嵐"
    else weather.to_s.humanize
    end
  end

  # 気分の日本語ラベルを返す
  def feeling_label
    return nil unless feeling
    case feeling.to_sym
    when :great then "最高！"
    when :good then "良い"
    when :normal then "普通"
    when :tired then "疲れた"
    when :exhausted then "ヘトヘト"
    else feeling.to_s.humanize
    end
  end

  private

  # カスタムバリデーションメソッド:完全に空の投稿を防ぐ
  def must_have_content
    if body.blank? && weather.nil? && feeling.nil? && walk_id.nil?
      errors.add(:base, "本文、天気、気分、散歩記録のいずれか1つは入力してください")
    end
  end
end
