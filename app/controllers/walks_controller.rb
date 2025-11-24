class WalksController < ApplicationController
  # ログインしていないユーザーはアクセスできないようにする
  before_action :authenticate_user!

  # show、edit、update、destroyアクションの前に、対象の散歩記録を取得する
  before_action :set_walk, only: [ :show, :edit, :update, :destroy ]

  # 散歩記録一覧ページ（GET /walks）
  def index
    # ログインしているユーザーの散歩記録だけを取得する
    # Walkモデルのdefault_scopeにより、日付順（新しい順）で自動ソートされる
    @walks = current_user.walks
  end

  # 散歩記録詳細ページ（GET /walks/:id）
  def show
    # before_actionで@walkが設定されているので、ここでは何もしない
  end

  # 新規散歩記録作成ページ（GET /walks/new）
  def new
    # 新しい散歩記録のインスタンスを作成
    # デフォルト値として今日の日付を設定
    @walk = Walk.new(walked_on: Date.today)
  end

  # 散歩記録編集ページ（GET /walks/:id/edit）
  def edit
    # before_actionで@walkが設定されているので、ここでは何もしない
  end

  # 散歩記録の作成処理（POST /walks）
  def create
    # ログインしているユーザーに紐づけて散歩記録を作成
    @walk = current_user.walks.build(walk_params)

    # データベースに保存を試みる
    if @walk.save
      # 保存に成功した場合、一覧ページにリダイレクトして成功メッセージを表示
      redirect_to walks_path, notice: t("flash.walks.create.notice")
    else
      # 保存に失敗した場合（バリデーションエラー）、新規作成ページを再表示
      render :new, status: :unprocessable_entity
    end
  end

  # 散歩記録の更新処理（PATCH/PUT /walks/:id）
  def update
    # 散歩記録を更新
    if @walk.update(walk_params)
      # 更新に成功した場合、詳細ページにリダイレクトして成功メッセージを表示
      redirect_to @walk, notice: t("flash.walks.update.notice")
    else
      # 更新に失敗した場合（バリデーションエラー）、編集ページを再表示
      render :edit, status: :unprocessable_entity
    end
  end

  # 散歩記録の削除処理（DELETE /walks/:id）
  def destroy
    # 散歩記録を削除
    @walk.destroy
    # 一覧ページにリダイレクトして削除完了メッセージを表示
    redirect_to walks_path, notice: t("flash.walks.destroy.notice")
  end

  private

  # 対象の散歩記録を取得するメソッド
  # ログインユーザーの散歩記録の中から、指定されたIDの記録を取得する
  # これにより、他のユーザーの散歩記録にアクセスできないようにする
  def set_walk
    @walk = current_user.walks.find(params[:id])
  end

  # フォームから送信されたパラメータを許可するメソッド
  # セキュリティのため、必要なパラメータだけを許可する
  def walk_params
    params.require(:walk).permit(:walked_on, :duration, :distance, :steps, :calories_burned, :location, :notes)
  end
end
