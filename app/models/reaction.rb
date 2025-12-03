class Reaction < ApplicationRecord
  # アソシエーション（他のモデルとの関連付け）
  belongs_to :user
  belongs_to :post

  # バリデーション（データの検証ルール）
  validates :kind, presence: true  # リアクションの種類（kind）は必須
  validates :user_id, uniqueness: {
    scope: [ :post_id, :kind ],
    message: "は同じ投稿に同じリアクションを複数回つけられません"
  }

  # enum（整数値に名前をつける機能）
  enum :kind, {
    thumbs_up: 0,      # 👍 いいね
    heart: 1,          # ❤️ 素敵
    bulb: 2,           # 💡 参考になる
    cherry_blossom: 3, # 🌸 癒やされる
    fire: 4,           # 🔥 すごい！
    party: 5,          # 🎉 おめでとう
    sun: 6,            # ☀️ 良い天気だね
    walking: 7         # 🚶 一緒に歩きたい
  }, prefix: true

  # インスタンスメソッド（各リアクションが持つ機能）
  def emoji
    case kind.to_sym
    when :thumbs_up then "👍"
    when :heart then "❤️"
    when :bulb then "💡"
    when :cherry_blossom then "🌸"
    when :fire then "🔥"
    when :party then "🎉"
    when :sun then "☀️"
    when :walking then "🚶"
    end
  end

  # リアクションのラベルを返す（日本語）
  def label
    case kind.to_sym
    when :thumbs_up then "いいね"
    when :heart then "素敵"
    when :bulb then "参考になる"
    when :cherry_blossom then "癒やされる"
    when :fire then "すごい！"
    when :party then "おめでとう"
    when :sun then "良い天気だね"
    when :walking then "一緒に歩きたい"
    end
  end

  # クラスメソッドで全リアクション種類を配列で返す（ビューで使用）
  # 例: [{ kind: :thumbs_up, emoji: "👍", label: "いいね" }, ...]
  def self.all_kinds
    kinds.keys.map do |kind_key|
      reaction = new(kind: kind_key)
      {
        kind: kind_key,
        emoji: reaction.emoji,
        label: reaction.label
      }
    end
  end
end
