class UsersController < ApplicationController
  # ログインしていないユーザーを弾く（実装済みの認証ヘルパーがあれば）
  # before_action :require_login

  before_action :set_user, only: %i[edit update]
  before_action :ensure_correct_user, only: %i[edit update]

  def edit
    # @user は before_action でセットされているので、ここは空でOK
  end

  def update
    # パスワードまたはメールアドレスの変更がある場合は、現在のパスワードが必要
    # params[:user][:email] が送信されていない（disabledの場合など）は変更なしとみなす
    password_changed = params[:user][:password].present?
    email_changed = params[:user][:email].present? && params[:user][:email] != @user.email

    if password_changed || email_changed
      success = @user.update_with_password(user_params)
    else
      # それ以外（名前や目標距離など）の変更はパスワード不要
      # update_without_password はパスワード検証をスキップして更新する
      params[:user].delete(:current_password) # 不要なパラメータを削除
      success = @user.update_without_password(user_params)
    end

    if success
      respond_to do |format|
        format.html { redirect_to edit_user_path(@user), notice: "プロフィールを更新しました" }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Google連携解除
  def disconnect_google
    # パスワード検証
    unless current_user.valid_password?(params[:user][:current_password])
      redirect_to edit_user_registration_path, alert: "パスワードが正しくありません"
      return
    end

    # Google関連の情報をクリア
    if current_user.update(
      google_uid: nil,
      google_token: nil,
      google_refresh_token: nil,
      google_expires_at: nil,
      use_google_avatar: false # 強制的にイニシャル表示に戻す
    )
      redirect_to edit_user_registration_path, notice: "Google連携を解除しました"
    else
      redirect_to edit_user_registration_path, alert: "連携解除に失敗しました。"
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

    # :email, :password, :password_confirmation, :target_distance, :current_password を追加で許可します
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password, :target_distance, :use_google_avatar)
  end

  # セキュリティ対策：ログインユーザー以外が編集画面にアクセスしようとしたら弾く
  def ensure_correct_user
    # current_user メソッドが定義されている前提です
    if @user != current_user
      redirect_to root_path, alert: "権限がありません"
    end
  end
end
