class ReminderLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reminder_log, only: [:mark_as_read]

  # 通知一覧
  def index
    # タブの種類を取得（デフォルトは'announcements'）
    @tab = params[:tab] || "announcements"

    # タブに応じて通知をフィルタリング
    @reminder_logs = case @tab
    when "reminders"
                       # リマインダーは作成日時の降順
                       current_user.reminder_logs.reminders.recent
    else # 'announcements'
                       # お知らせは公開日時の降順（ordered_by_announcementがorder句を持っているのでrecentは不要）
                       current_user.reminder_logs.announcements.includes(:announcement).ordered_by_announcement
    end

    @reminder_logs = @reminder_logs.page(params[:page]).per(20)

    # 各タブの未読数を取得
    @announcement_unread_count = current_user.reminder_logs.announcements.unread.count
    @reminder_unread_count = current_user.reminder_logs.reminders.unread.count
  end

  # 個別既読
  def mark_as_read
    @reminder_log.mark_as_read!
    redirect_to reminder_logs_path, notice: "通知を既読にしました"
  end

  # 一括既読
  def mark_all_as_read
    current_user.reminder_logs.unread.update_all(read_at: Time.current)
    redirect_to reminder_logs_path, notice: "すべての通知を既読にしました"
  end

  private

  def set_reminder_log
    @reminder_log = current_user.reminder_logs.find(params[:id])
  end
end
