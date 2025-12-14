class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [ :mark_as_read ]

  # 通知一覧
  def index
    # タブの種類を取得（デフォルトは'announcements'）
    @tab = params[:tab] || "announcements"

    # タブに応じて通知をフィルタリング
    @notifications = case @tab
    when "reminders"
                       # リマインダーは作成日時の降順
                       current_user.notifications.reminders.recent
    else  # 'announcements'
                       # お知らせは公開日時の降順（ordered_by_announcementがorder句を持っているのでrecentは不要）
                       current_user.notifications.announcements.includes(:announcement).ordered_by_announcement
    end

    @notifications = @notifications.page(params[:page]).per(20)

    # 各タブの未読数を取得
    @announcement_unread_count = current_user.notifications.announcements.unread.count
    @reminder_unread_count = current_user.notifications.reminders.unread.count
  end

  # 個別既読
  def mark_as_read
    @notification.mark_as_read!
    redirect_to notifications_path, notice: "通知を既読にしました"
  end

  # 一括既読
  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_to notifications_path, notice: "すべての通知を既読にしました"
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
