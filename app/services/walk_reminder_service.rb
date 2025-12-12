class WalkReminderService
  def self.send_reminders
    # 散歩リマインドが有効なユーザーを全て取得
    users = User.where(walk_reminder_enabled: true)

    users.find_each do |user|
      # 今日の散歩記録がある場合はスキップ
      next if user.walks.where(date: Date.current).exists?

      # ユーザーの設定時刻を取得（時と分のみ）
      reminder_hour = user.walk_reminder_time.hour
      reminder_min = user.walk_reminder_time.min

      # 現在時刻を取得（時と分のみ）
      current_time = Time.current
      current_hour = current_time.hour
      current_min = current_time.min

      # 時刻が一致する場合に通知（10分の範囲で許容）
      # 例: 17:08設定の場合、17:00～17:10の間に実行されれば通知
      if current_hour == reminder_hour && (current_min - reminder_min).abs <= 10
        WebPushService.send_notification(
          user,
          title: "散歩の時間です！",
          body: "今日の目標まであと少しです。軽く歩いてきませんか？",
          url: "/walks/new"
        )
        Rails.logger.info "Sent walk reminder to user #{user.id}"
      end
    end
  end
end
