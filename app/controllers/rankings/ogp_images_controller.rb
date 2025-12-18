module Rankings
  class OgpImagesController < ApplicationController
    skip_before_action :authenticate_user!, only: [ :show ]

    def show
      # キャッシュ設定: ランキングは変動するため12時間に設定
      expires_in 12.hours, public: true

      @user = User.find(params[:id])

      # 期間設定 (今週)
      start_date = Date.current.beginning_of_week
      end_date = Date.current.end_of_week
      period_key = "#{start_date.strftime('%Y%m%d')}_#{end_date.strftime('%Y%m%d')}"

      # 【デバッグ用】既存画像チェックを一時的に無効化して、強制再生成
      # if @user.ranking_ogp_image.attached? &&
      #    @user.ranking_ogp_image.filename.to_s.include?(period_key) &&
      #    @user.ranking_ogp_image.blob.created_at > 12.hours.ago
      #   redirect_to rails_blob_url(@user.ranking_ogp_image, disposition: "inline"), allow_other_host: true
      #   return
      # end

      # 画像がない、または古い場合
      # コントローラー内で同期的に生成（投稿OGPと同じパターン）

      # 週間データ集計
      Rails.logger.info "[Ranking OGP] User: #{@user.id}, Period: #{period_key}"
      weekly_walks = @user.walks.where(walked_on: start_date..end_date)
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
        user: @user,
        title: "RANKING CHAMPION",
        message: "今週のランキング結果！\n目指せトップランカー！",
        stats: stats,
        theme: :ranking
      ).generate

      Rails.logger.info "[Ranking OGP] Image generated, size: #{image_data.bytesize} bytes"
      Rails.logger.info "[Ranking OGP] Before attach - attached?: #{@user.ranking_ogp_image.attached?}"

      # Active Storageに保存
      @user.ranking_ogp_image.attach(
        io: StringIO.new(image_data),
        filename: "ranking_#{@user.id}_#{period_key}.jpg",
        content_type: "image/jpeg"
      )

      Rails.logger.info "[Ranking OGP] After attach - attached?: #{@user.ranking_ogp_image.attached?}"

      # 明示的にリロードして、DBの状態を確認
      @user.reload
      Rails.logger.info "[Ranking OGP] After reload - attached?: #{@user.ranking_ogp_image.attached?}"

      if @user.ranking_ogp_image.attached?
        blob_url = rails_blob_url(@user.ranking_ogp_image, disposition: "inline")
        Rails.logger.info "[Ranking OGP] Success! Blob URL: #{blob_url}"
        redirect_to blob_url, allow_other_host: true
      else
        Rails.logger.error "[Ranking OGP] CRITICAL: attach() completed but image not attached after reload!"
        redirect_to ActionController::Base.helpers.image_url("icon.png"), allow_other_host: true
      end

    rescue => e
      Rails.logger.error "Failed to handle ranking OGP image request: #{e.message}"
      # エラー時もデフォルト画像へ
      redirect_to ActionController::Base.helpers.image_url("icon.png"), allow_other_host: true
    end
  end
end
