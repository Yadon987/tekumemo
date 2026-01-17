class Posts::OgpImagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  def show
    @post = Post.find(params[:post_id])
    Rails.logger.info "Generating OGP image for Post ID: #{@post.id}"

    # 強制リフレッシュ: ?refresh=true があれば既存の画像を削除
    if params[:refresh] == "true"
      expires_now
      if @post.ogp_image.attached?
        Rails.logger.info "Force refreshing OGP image for Post ID: #{@post.id}"
        @post.ogp_image.purge
        @post.reload
      end
    else
      # OGP画像は投稿作成後不変なので、1ヶ月キャッシュしてサーバー負荷を削減
      expires_in 1.month, public: true
    end

    begin
      # 既存の画像があればそれを返す（Active Storage経由でCloudinaryから配信）
      if @post.ogp_image.attached?
        redirect_to rails_blob_url(@post.ogp_image, disposition: "inline"), allow_other_host: true
        return
      end

      # 画像が未保存の場合、生成してActive Storageに保存
      user = @post.user
      walk = @post.walk || user.walks.find_by(walked_on: @post.created_at.to_date)

      # レベル計算
      level = StatsService.new(user).level

      # 統計情報
      stats = {
        level: level,
        date: walk&.walked_on&.strftime("%Y-%m-%d") || @post.created_at.strftime("%Y-%m-%d"),
        label1: "DISTANCE",
        value1: "#{walk&.kilometers || 0} km",
        label2: "EXP (STEPS)",
        value2: "#{walk&.steps || 0}",
        label3: "LOCATION",
        value3: walk&.location.presence || "TekuMemo"
      }

      image_data = RpgCardGeneratorService.new(
        user: user,
        title: "QUEST COMPLETE",
        message: @post.content,
        stats: stats,
        theme: :quest
      ).generate

      # Active Storageに保存（Cloudinaryへアップロード）
      @post.ogp_image.attach(
        io: StringIO.new(image_data),
        filename: "post_#{@post.id}_ogp.jpg",
        content_type: "image/jpeg"
      )

      # 保存した画像のURLにリダイレクト
      redirect_to rails_blob_url(@post.ogp_image, disposition: "inline"), allow_other_host: true
    rescue StandardError => e
      Rails.logger.error "Failed to generate OGP image for Post ID #{@post.id}: #{e.message}\n#{e.backtrace.join("\n")}"

      # デフォルトのOGP画像にフォールバック（空白画像を避ける）
      # アプリアイコンを代替として使用
      redirect_to ActionController::Base.helpers.image_url("icon.png"), allow_other_host: true
    end
  end
end
