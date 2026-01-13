class GenerateRankingOgpImageJob < ApplicationJob
  queue_as :default

  def perform(user, force: false)
    return unless user

    # 期間設定 (今週)
    start_date = Date.current.beginning_of_week
    end_date = Date.current.end_of_week
    period_key = "#{start_date.strftime('%Y%m%d')}_#{end_date.strftime('%Y%m%d')}"

    # 既に画像があり、期間キーが一致し、作成から24時間以内ならスキップ（強制フラグがない場合）
    if !force &&
       user.ranking_ogp_image.attached? &&
       user.ranking_ogp_image.filename.to_s.include?(period_key) &&
       user.ranking_ogp_image.blob.created_at > 24.hours.ago
      return
    end

    Rails.logger.info "Starting background Ranking OGP generation for User ID: #{user.id}"

    begin
      # 週間データ集計と順位計算をモデルに委譲
      stats = user.weekly_ranking_stats

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
    rescue StandardError => e
      Rails.logger.error "Background Ranking OGP generation failed: #{e.message}"
    end
  end
end
