class WalkReminderService
  def self.send_reminders
    # 散歩リマインドが有効なユーザーを全て取得
    users = User.where(walk_reminder_enabled: true)

    users.find_each do |user|
      # 今日の散歩記録がある場合はスキップ
      next if user.walks.where(walked_on: Date.current).exists?

      # ユーザーの設定時刻を取得（時と分のみ）
      reminder_hour = user.walk_reminder_time.hour
      reminder_min = user.walk_reminder_time.min


      # 現在時刻を取得（時のみ）
      current_time = Time.current
      current_hour = current_time.hour

      # 時刻が一致する場合に通知（1時間ごとの実行を想定し、時が一致すれば通知）
      if current_hour == reminder_hour
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
