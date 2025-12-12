class WalkReminderService
  def self.send_reminders
    current_time = Time.current
    current_hour = current_time.hour
    current_minute = current_time.min

    # 設定時刻が現在時刻（分まで）と一致するユーザーを検索
    # 実際にはcron等の実行間隔に合わせて「現在時刻〜現在時刻+N分」の範囲で検索するのが一般的だが、
    # ここではシンプルに「時」が一致し、「分」が現在時刻に近いユーザーを対象とする
    # ※ 本番運用では、10分おきに実行し、前後5分のユーザーを対象にするなどの調整が必要

    # 今回は「時」が一致するユーザー全員に送る（ただし、すでに今日の散歩記録がある場合は送らない）
    users = User.where(walk_reminder_enabled: true)
                .where("EXTRACT(HOUR FROM walk_reminder_time) = ?", current_hour)

    users.find_each do |user|
      # 今日の散歩記録を確認
      next if user.walks.where(date: Date.current).exists?

      WebPushService.send_notification(
        user,
        title: "散歩の時間です！",
        body: "今日の目標まであと少しです。軽く歩いてきませんか？",
        url: "/walks/new"
      )
    end
  end
end
