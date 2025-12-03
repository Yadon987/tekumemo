class PostsController < ApplicationController
  before_action :authenticate_user!

  # GET /posts
  # タイムライン（みんなの投稿）を表示
  def index
    # 全投稿を10件ずつ取得（N+1対策済み）
    @posts = Post.with_associations.recent.page(params[:page]).per(10)
    # 新規投稿フォーム用
    @post = Post.new
  end

  # GET /posts/mine
  # 投稿履歴（自分の投稿のみ）を表示
  def mine
    # 自分の投稿のみを10件ずつ取得
    @posts = current_user.posts.with_associations.recent.page(params[:page]).per(10)
    @post = Post.new
    # index と同じビューを使用
    render :index
  end

  # POST /posts
  # 新規投稿を作成
  def create
    # ログインユーザーの投稿として作成
    @post = current_user.posts.build(post_params)

    if @post.save
      # 成功：元のページに戻る
      redirect_back(fallback_location: posts_path, notice: '投稿しました！')
    else
      # 失敗：Turbo Streamでフォーム部分だけをエラーメッセージ付きで更新
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("new_post_form", partial: "posts/form", locals: { post: @post })
        end
        format.html do
          @posts = Post.with_associations.recent.page(params[:page]).per(10)
          flash.now[:alert] = '投稿に失敗しました'
          render :index, status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /posts/:id
  # 投稿を削除
  def destroy
    # 自分の投稿のみ削除可能（他人の投稿は RecordNotFound）
    post = current_user.posts.find(params[:id])
    post.destroy!
    redirect_back(fallback_location: posts_path, notice: '投稿を削除しました', status: :see_other)
  end

  private

  # 許可するパラメータを指定
  def post_params
    params.require(:post).permit(:body, :weather, :feeling, :walk_id)
  end
end
