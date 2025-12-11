class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [ :mark_as_read ]

  # 通知一覧
  def index
    @notifications = current_user.notifications
                                  .includes(:announcement)
                                  .recent
                                  .page(params[:page])
                                  .per(20)
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
