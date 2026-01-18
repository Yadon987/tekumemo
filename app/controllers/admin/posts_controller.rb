class Admin::PostsController < Admin::BaseController
  def index
    @posts = Post.with_associations

    # 検索（本文・ユーザー名）
    if params[:q].present?
      search_term = "%#{params[:q]}%"
      @posts = @posts.joins(:user).where("posts.body ILIKE ? OR users.name ILIKE ?", search_term, search_term)
    end

    # フィルタ（天気）
    @posts = @posts.where(weather: params[:weather]) if params[:weather].present?

    # フィルタ（気分）
    @posts = @posts.where(feeling: params[:feeling]) if params[:feeling].present?

    @posts = @posts.recent.page(params[:page]).per(20)
  end

  def show
    @post = Post.find(params[:id])
  end

  def destroy
    @post = Post.find(params[:id])
    post_user_name = @post.user.name
    @post.destroy
    redirect_to admin_posts_path, notice: "「#{post_user_name}」さんの投稿を削除しました"
  end
end
