namespace :reminder do
  desc "散歩時間のリマインドを送信（1時間ごとに実行推奨）"
  task walk: :environment do
    Rails.logger.info "Starting walk reminder task..."
    WalkReminderService.send_reminders
    Rails.logger.info "Walk reminder task completed."
  end

  desc "非アクティブユーザーへのリマインドを送信（1日1回実行推奨）"
  task inactive: :environment do
    Rails.logger.info "Starting inactive reminder task..."
    InactiveReminderService.send_reminders
    Rails.logger.info "Inactive reminder task completed."
  end

  desc "リアクションのまとめ通知を送信（1日1回実行推奨、夕方〜夜がおすすめ）"
  task reaction_summary: :environment do
    Rails.logger.info "Starting reaction summary task..."
    ReactionSummaryService.send_summaries
    Rails.logger.info "Reaction summary task completed."
  end
end
