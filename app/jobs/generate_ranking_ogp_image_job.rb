class GenerateRankingOgpImageJob < ApplicationJob
  queue_as :default

  def perform(user)
    return unless user

    # 期間設定 (今週)
    start_date = Date.current.beginning_of_week
    end_date = Date.current.end_of_week
    period_key = "#{start_date.strftime('%Y%m%d')}_#{end_date.strftime('%Y%m%d')}"

    # 既に画像があり、期間キーが一致し、作成から12時間以内ならスキップ
    if user.ranking_ogp_image.attached? &&
       user.ranking_ogp_image.filename.to_s.include?(period_key) &&
       user.ranking_ogp_image.blob.created_at > 12.hours.ago
      return
    end

    Rails.logger.info "Starting background Ranking OGP generation for User ID: #{user.id}"

    begin
      # 週間データ集計
      weekly_walks = user.walks.where(walked_on: start_date..end_date)
      total_distance = weekly_walks.sum(:distance)
      total_steps = weekly_walks.sum(:steps)

      # 順位計算
      higher_rank_users_count = User.joins(:walks)
                                    .where(walks: { walked_on: start_date..end_date })
                                    .group("users.id")
                                    .having("SUM(walks.steps) > ?", total_steps)
                                    .pluck("users.id")
                                    .count

      rank = higher_rank_users_count + 1
      rank_with_ordinal = rank.ordinalize

      stats = {
        level: nil,
        date: "#{start_date.strftime('%m/%d')} - #{end_date.strftime('%m/%d')}",
        label1: "RANK",
        value1: rank_with_ordinal,
        label2: "STEPS",
        value2: ActiveSupport::NumberHelper.number_to_delimited(total_steps),
        label3: "DISTANCE",
        value3: "#{total_distance.round(1)} km"
      }

      image_data = RpgCardGeneratorService.new(
        user: user,
        title: "RANKING CHAMPION",
        message: "今週のランキング結果！\n目指せトップランカー！",
        stats: stats,
        theme: :ranking
      ).generate

      # Active Storageに保存
      user.ranking_ogp_image.attach(
        io: StringIO.new(image_data),
        filename: "ranking_#{user.id}_#{period_key}.jpg",
        content_type: "image/jpeg"
      )

      Rails.logger.info "Background Ranking OGP generation completed for User ID: #{user.id}"
    rescue => e
      Rails.logger.error "Background Ranking OGP generation failed: #{e.message}"
    end
  end
end
