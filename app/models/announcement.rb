class Announcement < ApplicationRecord
  # バリデーション
  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true
  validates :announcement_type, inclusion: { in: %w[info warning urgent] }

  # お知らせの種類
  ANNOUNCEMENT_TYPES = {
    'info' => 'お知らせ',
    'warning' => '重要',
    'urgent' => '緊急'
  }.freeze

  # スコープ: 公開中のお知らせ
  scope :published, -> { where(is_published: true).where('published_at <= ?', Time.current) }
  scope :active, -> {
    published.where('expires_at IS NULL OR expires_at > ?', Time.current)
  }
  scope :by_priority, -> { order(priority: :desc, published_at: :desc) }

  # 公開中かどうか
  def active?
    is_published &&
      published_at.present? &&
      published_at <= Time.current &&
      (expires_at.nil? || expires_at > Time.current)
  end

  # お知らせ種類の日本語名
  def type_name
    ANNOUNCEMENT_TYPES[announcement_type] || 'お知らせ'
  end
end
