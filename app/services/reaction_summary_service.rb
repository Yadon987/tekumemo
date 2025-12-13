class ReactionSummaryService
  def self.send_summaries
    # 前日のリアクションを集計
    yesterday = Date.yesterday
    start_time = yesterday.beginning_of_day
    end_time = yesterday.end_of_day

    # 前日に作成されたリアクションを取得
    reactions = Reaction.where(created_at: start_time..end_time)
                        .includes(:post, :user)

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
        "#{reaction.emoji}#{count}件"
      end.join(", ")

      # 通知を送信
      WebPushService.send_notification(
        recipient,
        title: "リアクションまとめ",
        body: "昨日は#{total_count}件のリアクションがありました！#{summary_text}",
        url: "/posts"
      )

      Rails.logger.info "Sent reaction summary to user #{recipient.id}: #{total_count} reactions"
    end
  end
end
