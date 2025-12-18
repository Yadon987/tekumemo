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

      begin
        # 既存の画像があり、ファイル名が今週のもので、かつ作成から12時間以内であれば返す
        if @user.ranking_ogp_image.attached? &&
           @user.ranking_ogp_image.filename.to_s.include?(period_key) &&
           @user.ranking_ogp_image.blob.created_at > 12.hours.ago
          redirect_to rails_blob_url(@user.ranking_ogp_image, disposition: "inline"), allow_other_host: true
          return
        end


        # 週間データ集計
        weekly_walks = @user.walks.where(walked_on: start_date..end_date)
        total_distance = weekly_walks.sum(:distance)
        total_steps = weekly_walks.sum(:steps)

        # 順位計算 (簡易版: 全ユーザーの中で歩数順)
        higher_rank_users_count = User.joins(:walks)
                                      .where(walks: { walked_on: start_date..end_date })
                                      .group("users.id")
                                      .having("SUM(walks.steps) > ?", total_steps)
                                      .pluck("users.id")
                                      .count

        rank = higher_rank_users_count + 1
        rank_with_ordinal = rank.ordinalize # 1st, 2nd, 3rd...

        stats = {
          level: nil, # ランキングにはレベルを表示しない
          date: "#{start_date.strftime('%m/%d')} - #{end_date.strftime('%m/%d')}",
          label1: "RANK",
          value1: rank_with_ordinal,
          label2: "STEPS",
          value2: ActiveSupport::NumberHelper.number_to_delimited(total_steps), # カンマ区切り
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

        # 古い画像があれば削除
        @user.ranking_ogp_image.purge if @user.ranking_ogp_image.attached?

        # Active Storageに保存（Cloudinaryへアップロード）
        @user.ranking_ogp_image.attach(
          io: StringIO.new(image_data),
          filename: "ranking_#{@user.id}_#{period_key}.jpg",
          content_type: "image/jpeg"
        )

        # 保存した画像のURLにリダイレクト
        redirect_to rails_blob_url(@user.ranking_ogp_image, disposition: "inline"), allow_other_host: true
      rescue => e
        Rails.logger.error "Failed to generate ranking OGP image: #{e.message}\n#{e.backtrace.join("\n")}"
        head :internal_server_error
      end
    end
  end
end
