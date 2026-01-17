class InactiveReminderService
  def self.send_reminders
    # 非アクティブリマインドが有効なユーザーを取得
    User.where(is_inactive_reminder: true).find_in_batches do |batch|
      user_ids = batch.map(&:id)
      # 最終散歩日をまとめて取得
      last_walk_dates = Walk.where(user_id: user_ids).group(:user_id).maximum(:walked_on)

      batch.each do |user|
        # 最終散歩日を取得（なければ登録日）
        last_walk_date = last_walk_dates[user.id] || user.created_at.to_date

        # 経過日数を計算
        days_since_last_walk = (Date.current - last_walk_date).to_i

        # 設定された日数と一致する場合のみ通知（毎日送らないようにするため）
        next unless days_since_last_walk == user.inactive_days

        message_body = "#{days_since_last_walk}日間、散歩の記録がありません。今日は少し歩いてみませんか？"

        # Web Push通知を送信
        WebPushService.send_notification(
          user,
          title: "お久しぶりです！",
          body: message_body,
          url: "/walks/new"
        )

        # 通知ボックスにも保存（リマインダーは既読状態で作成）
        user.reminder_logs.create!(
          category: :inactive_reminder,
          message: message_body,
          url: "/walks/new",
          read_at: Time.current
        )

        Rails.logger.info "Sent inactive reminder to user #{user.id} (#{days_since_last_walk} days inactive)"
      end
    end
  end
end
