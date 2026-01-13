class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :announcement, optional: true

  # Rails 7.2+ では enum 使用前に型を明示的に宣言する必要がある
  attribute :category, :integer, default: 0

  # 通知種類のenum
  enum :category, {
    announcement: 0,           # 運営からのお知らせ
    inactive_reminder: 1,      # 非アクティブリマインド
    reaction_summary: 2        # リアクションまとめ
  }, prefix: true

  # 未読通知のみを取得するスコープ
  scope :unread, -> { where(read_at: nil) }
  # 既読通知のみを取得するスコープ
  scope :read, -> { where.not(read_at: nil) }
  # 新しい順に並べ替え
  scope :recent, -> { order(created_at: :desc) }
  # お知らせの公開日順に並べ替え
  scope :ordered_by_announcement, lambda {
    joins(:announcement).order("announcements.published_at DESC, notifications.created_at DESC")
  }
  # リマインダー通知のみ
  scope :reminders, -> { where(category: %i[inactive_reminder reaction_summary]) }
  # お知らせのみ
  scope :announcements, -> { where(category: :announcement) }

  # 既読にする
  def mark_as_read!
    update!(read_at: Time.current) if read_at.nil?
  end

  # 未読かどうか
  def unread?
    read_at.nil?
  end

  # 通知のタイトルを取得（お知らせの場合はannouncementのtitle、リマインダーの場合は種類に応じたタイトル）
  def title
    if category_announcement?
      announcement&.title
    elsif category_inactive_reminder?
      "お久しぶりです！"
    elsif category_reaction_summary?
      "リアクションまとめ"
    end
  end

  # 通知の本文を取得
  def body
    if category_announcement?
      announcement&.body
    else
      message
    end
  end

  # 通知のリンク先を取得
  def link_url
    if category_announcement?
      nil # お知らせは詳細モーダルで表示
    else
      url
    end
  end
end
