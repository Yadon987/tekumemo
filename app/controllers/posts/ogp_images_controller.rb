class Posts::OgpImagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show ]

  def show
    # OGP画像は投稿作成後不変なので、1ヶ月キャッシュしてサーバー負荷を削減
    expires_in 1.month, public: true

    @post = Post.find(params[:post_id])
    Rails.logger.info "Generating OGP image for Post ID: #{@post.id}"

    begin
      # 既存の画像があればそれを返す（Active Storage経由でCloudinaryから配信）
      if @post.ogp_image.attached?
        redirect_to rails_blob_url(@post.ogp_image, disposition: "inline"), allow_other_host: true
        return
      end

      # 画像が未保存の場合、生成してActive Storageに保存
      user = @post.user
      walk = @post.walk || user.walks.find_by(walked_on: @post.created_at.to_date)

      # レベル計算 (StatsServiceと同じロジック: 累計距離ベース)
      lifetime_distance = user.walks.sum(:distance)
      level = case lifetime_distance
      when 0...10 then 1
      when 10...30 then 2
      when 30...60 then 3
      when 60...100 then 4
      when 100...150 then 5
      when 150...220 then 6
      when 220...300 then 7
      when 300...400 then 8
      when 400...550 then 9
      else 10 + ((lifetime_distance - 550) / 200).to_i
      end

      # 統計情報
      stats = {
        level: level,
        date: walk&.walked_on&.strftime("%Y-%m-%d") || @post.created_at.strftime("%Y-%m-%d"),
        label1: "DISTANCE",
        value1: "#{walk&.distance || 0} km",
        label2: "EXP (STEPS)",
        value2: "#{walk&.steps || 0}",
        label3: "LOCATION",
        value3: walk&.location.presence || "TekuMemo"
      }

      image_data = RpgCardGeneratorService.new(
        user: user,
        title: "QUEST COMPLETE",
        message: @post.body,
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
    rescue => e
      Rails.logger.error "Failed to generate OGP image: #{e.message}\n#{e.backtrace.join("\n")}"
      head :internal_server_error
    end
  end
end
