class InactiveReminderService
  def self.send_reminders
    # 非アクティブリマインドが有効なユーザーを取得
    users = User.where(inactive_days_reminder_enabled: true)

    users.find_each do |user|
      # 最終散歩日を取得（なければ登録日）
      last_walk_date = user.walks.maximum(:walked_on) || user.created_at.to_date

      # 経過日数を計算
      days_since_last_walk = (Date.current - last_walk_date).to_i

      # 設定された日数と一致する場合のみ通知（毎日送らないようにするため）
      if days_since_last_walk == user.inactive_days_threshold
        WebPushService.send_notification(
          user,
          title: "お久しぶりです！",
          body: "#{days_since_last_walk}日間、散歩の記録がありません。今日は少し歩いてみませんか？",
          url: "/walks/new"
        )
      end
    end
  end
end
