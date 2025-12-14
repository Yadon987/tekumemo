class Admin::PostsController < Admin::BaseController
  def index
    @posts = Post.with_associations.recent.page(params[:page]).per(20)
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
