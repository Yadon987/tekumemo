class Announcement < ApplicationRecord
  # 関連付け
  has_many :notifications, dependent: :destroy

  # バリデーション
  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true
  validates :announcement_type, inclusion: { in: %w[info warning urgent] }

  # コールバック: 公開時に全ユーザーに通知を作成
  after_commit :create_notifications_for_users, on: [ :create, :update ], if: :should_create_notifications?

  # お知らせの種類
  ANNOUNCEMENT_TYPES = {
    "info" => "お知らせ",
    "warning" => "重要",
    "urgent" => "緊急"
  }.freeze

  # スコープ: 公開中のお知らせ
  scope :published, -> { where(is_published: true).where("published_at <= ?", Time.current) }
  scope :active, -> {
    published.where("expires_at IS NULL OR expires_at > ?", Time.current)
  }
  scope :recent, -> { order(published_at: :desc) }

  # 公開中かどうか
  def active?
    is_published &&
      published_at.present? &&
      published_at <= Time.current &&
      (expires_at.nil? || expires_at > Time.current)
  end

  # お知らせ種類の日本語名
  def type_name
    ANNOUNCEMENT_TYPES[announcement_type] || "お知らせ"
  end

  private

  # 通知を作成すべきかどうか
  def should_create_notifications?
    # 公開状態に変更された場合のみ通知を作成
    saved_change_to_is_published? && is_published?
  end

  # 全ユーザーに通知を作成
  def create_notifications_for_users
    # すでに通知が作成されている場合はスキップ
    return if notifications.exists?

    User.find_each do |user|
      notifications.create!(user: user)
    end
  end
end
