class ReactionSummaryService
  def self.send_summaries
    # 今日のリアクションを集計（0時〜現在まで）
    today = Date.current
    start_time = today.beginning_of_day
    end_time = Time.current

    # 今日作成されたリアクションを取得
    reactions = Reaction.where(created_at: start_time..end_time)
                        .includes(:user, post: :user)

    # リアクションがない場合は処理を終了
    return if reactions.empty?

    # 投稿者（リアクションを受け取った人）ごとにグループ化
    reactions_by_recipient = reactions.group_by { |reaction| reaction.post.user }

    reactions_by_recipient.each do |recipient, user_reactions|
      # 通知設定が無効な場合はスキップ
      next unless recipient.reaction_summary_enabled

      # リアクション数を集計
      total_count = user_reactions.size

      # リアクションの種類別にカウント
      reactions_by_kind = user_reactions.group_by(&:kind).transform_values(&:count)

      # 上位3種類のリアクションを取得
      top_reactions = reactions_by_kind.sort_by { |_, count| -count }.take(3)

      # 通知メッセージを作成
      summary_text = top_reactions.map do |kind, count|
        reaction = Reaction.new(kind: kind)
        emoji = reaction.emoji || "?"  # emojiが取得できない場合は"?"
        "#{emoji}#{count}件"
      end.join(", ")

      # 通知を送信
      message_body = "今日これまでに#{total_count}件のリアクションがありました！#{summary_text}"

      WebPushService.send_notification(
        recipient,
        title: "リアクションまとめ",
        body: message_body,
        url: "/posts"
      )

      # 通知ボックスにも保存（リマインダーは既読状態で作成）
      recipient.notifications.create!(
        notification_type: :reaction_summary,
        message: message_body,
        url: "/posts",
        read_at: Time.current
      )

      Rails.logger.info "Sent reaction summary to user #{recipient.id}: #{total_count} reactions"
    end
  end
end
