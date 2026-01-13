class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:show]

  # GET /posts
  # タイムライン（みんなの投稿）を表示
  def index
    # 全投稿を10件ずつ取得（N+1対策済み）
    @posts = Post.with_associations.recent.page(params[:page]).per(10)
    # 新規投稿フォーム用
    @post = Post.new
  end

  # GET /posts/:id
  # 投稿詳細（シェア用ページ）
  def show
    @post = Post.find(params[:id])
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
    # ゲストユーザーは投稿不可
    if current_user.guest?
      redirect_to posts_path, alert: "ゲストモードでは投稿機能は利用できません。"
      return
    end

    # ログインユーザーの投稿として作成
    @post = current_user.posts.build(post_params)

    # セキュリティ対策：他人の散歩記録を紐付けられないようにチェック
    if @post.walk_id.present? && !current_user.walks.exists?(id: @post.walk_id)
      redirect_to posts_path, alert: "不正な操作です。指定された散歩記録は存在しないか、権限がありません。"
      return
    end

    if @post.save
      # OGP画像をバックグラウンドで生成（シェア時の高速化）
      GeneratePostOgpImageJob.perform_later(@post)

      # 成功：セッションに投稿IDを保存してモーダル表示フラグを立てる
      session[:show_post_success_modal] = @post.id
      # 投稿一覧ページに明示的にリダイレクト（モーダル表示のため）
      redirect_to posts_path, notice: "投稿しました！"
    else
      # 失敗：Turbo Streamでフォーム部分だけをエラーメッセージ付きで更新
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("new_post_form", partial: "posts/form", locals: { post: @post })
        end
        format.html do
          @posts = Post.with_associations.recent.page(params[:page]).per(10)
          # エラーメッセージを具体的に表示して、ユーザーが修正できるようにする
          flash.now[:alert] = "投稿に失敗しました: #{@post.errors.full_messages.join(', ')}"
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
    redirect_back(fallback_location: posts_path, notice: "投稿を削除しました", status: :see_other)
  end

  private

  # 許可するパラメータを指定
  def post_params
    params.require(:post).permit(:body, :weather, :feeling, :walk_id)
  end
end
