class UsersController < ApplicationController
  # ログインしていないユーザーを弾く（実装済みの認証ヘルパーがあれば）
  # before_action :require_login

  before_action :set_user, only: %i[edit update]
  before_action :ensure_correct_user, only: %i[edit update]

  def edit
    # @user は before_action でセットされているので、ここは空でOK
  end

  def update
    if @user.update(user_params)
      respond_to do |format|
        format.html { redirect_to edit_user_path(@user), notice: "プロフィールを更新しました" }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # ストロングパラメーター
  def user_params
    # パスワード入力欄が空（未入力）の場合の処理
    # Deviseはパスワードが空文字だとエラーになったり意図しない挙動になることがあるため、
    # 空の場合はパラメータ自体からキーを削除して「変更なし」として扱います。
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    # :email, :password, :password_confirmation, :target_distance を追加で許可します
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :target_distance, :use_google_avatar)
  end

  # セキュリティ対策：ログインユーザー以外が編集画面にアクセスしようとしたら弾く
  def ensure_correct_user
    # current_user メソッドが定義されている前提です
    if @user != current_user
      redirect_to root_path, alert: "権限がありません"
    end
  end
end
