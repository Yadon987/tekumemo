class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :announcement

  # 未読通知のみを取得するスコープ
  scope :unread, -> { where(read_at: nil) }
  # 既読通知のみを取得するスコープ
  scope :read, -> { where.not(read_at: nil) }
  # 新しい順に並べ替え
  scope :recent, -> { order(created_at: :desc) }

  # 既読にする
  def mark_as_read!
    update!(read_at: Time.current) if read_at.nil?
  end

  # 未読かどうか
  def unread?
    read_at.nil?
  end
end
