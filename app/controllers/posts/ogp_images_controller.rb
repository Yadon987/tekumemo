class Posts::OgpImagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show ]

  def show
    # OGP画像は投稿作成後不変なので、1ヶ月キャッシュしてサーバー負荷を削減
    expires_in 1.month, public: true

    @post = Post.find(params[:post_id])
    Rails.logger.info "Generating OGP image for Post ID: #{@post.id}"

    begin
      image_data = OgpImageGeneratorService.new(@post).generate
      send_data image_data, type: "image/png", disposition: "inline"
    rescue => e
      Rails.logger.error "Failed to generate OGP image: #{e.message}"
      head :internal_server_error
    end
  end
end
