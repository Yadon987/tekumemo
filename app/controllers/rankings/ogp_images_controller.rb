module Rankings
  class OgpImagesController < ApplicationController
    skip_before_action :authenticate_user!, only: [:show]

    def show
      @user = User.find(params[:id])

      # 期間設定 (今週)
      start_date = Date.current.beginning_of_week
      end_date = Date.current.end_of_week
      period_key = "#{start_date.strftime('%Y%m%d')}_#{end_date.strftime('%Y%m%d')}"

      # 強制リフレッシュ: ?refresh=true があれば既存の画像を削除
      if params[:refresh] == "true"
        expires_now # キャッシュを無効化
        if @user.ranking_ogp_image.attached?
          Rails.logger.info "[Ranking OGP] Force refreshing image for user #{@user.id}"
          @user.ranking_ogp_image.purge
          @user.reload # アタッチメント情報を更新
        end
      else
        # キャッシュ設定: 手動更新機能があるため、1週間に設定してサーバー負荷を軽減
        expires_in 1.week, public: true
      end

      # 既存の画像があり、ファイル名が今週のもので、かつ作成から1週間以内であれば返す
      if @user.ranking_ogp_image.attached? &&
         @user.ranking_ogp_image.filename.to_s.include?(period_key) &&
         @user.ranking_ogp_image.blob.created_at > 1.week.ago
        send_data @user.ranking_ogp_image.download, type: "image/jpeg", disposition: "inline"
        return
      end

      # 画像がない、または古い場合
      # コントローラー内で同期的に生成（投稿OGPと同じパターン）

      # 週間データ集計と順位計算をモデルに委譲
      stats = @user.weekly_ranking_stats

      image_data = RpgCardGeneratorService.new(
        user: @user,
        title: "RANKING CHAMPION",
        message: "今週のランキング結果です！\n目指せトップランカー！",
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
        Rails.logger.info "[Ranking OGP] Success! Serving image directly."
        send_data @user.ranking_ogp_image.download, type: "image/jpeg", disposition: "inline"
      else
        Rails.logger.error "[Ranking OGP] CRITICAL: attach() completed but image not attached after reload!"
        redirect_to ActionController::Base.helpers.image_url("icon.png"), allow_other_host: true
      end
    rescue StandardError => e
      Rails.logger.error "Failed to handle ranking OGP image request: #{e.message}"
      # エラー時もデフォルト画像へ
      redirect_to ActionController::Base.helpers.image_url("icon.png"), allow_other_host: true
    end
  end
end
