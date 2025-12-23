class UsersController < ApplicationController
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
      avatar_type: :default # アバター種別をデフォルトに戻す
    )
      redirect_to edit_user_registration_path, notice: "Google連携を解除しました"
    else
      redirect_to edit_user_registration_path, alert: "連携解除に失敗しました。"
    end
  end
end
