class Reaction < ApplicationRecord
  # アソシエーション（他のモデルとの関連付け）
  belongs_to :user
  belongs_to :post, touch: true

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
    fire: 4,           # 🔥 燃えてきた！
    party: 5,          # 🎉 おめでとう
    eyes: 8,           # 👀 見たよ
    sparkles: 10,      # ✨ きれい
    muscle: 11,        # 💪 頑張った
    laugh: 12,         # 🤣 爆笑
    thanks: 13,        # 🙏 ありがとう
    cry: 14            # 😭 涙
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
    when :eyes then "👀"
    when :sparkles then "✨"
    when :muscle then "💪"
    when :laugh then "🤣"
    when :thanks then "🙏"
    when :cry then "😭"
    end
  end

  # リアクションのラベルを返す（日本語）
  def label
    case kind.to_sym
    when :thumbs_up then "いいね"
    when :heart then "素敵"
    when :bulb then "参考になる"
    when :cherry_blossom then "癒やされる"
    when :fire then "燃えてきた！"
    when :party then "おめでとう"
    when :eyes then "見たよ"
    when :sparkles then "きれい"
    when :muscle then "頑張った"
    when :laugh then "爆笑"
    when :thanks then "ありがとう"
    when :cry then "涙"
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
