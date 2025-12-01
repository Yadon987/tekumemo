# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # ユーザー情報の更新前に、許可するパラメータを追加する
  before_action :configure_account_update_params, only: [ :update ]

  # GET /resource/edit
  # Deviseのデフォルトのeditアクションをそのまま使うので、オーバーライド不要
  # ただし、ビューは app/views/devise/registrations/edit.html.erb を使うことになる

  # PUT /resource
  # 更新処理
  def update
    # Google連携済みなどでパスワードなしで更新したい場合のロジック
    # Devise標準の update_resource をオーバーライドしてもいいが、
    # ここでは super を呼ぶ前にパラメータを調整したり、
    # update_resource メソッド自体をオーバーライドするのが一般的。
    super
  end

  # Google連携解除アクション
  # これはDevise標準にはないので、独自に追加
  def disconnect_google
    if current_user.update(
      google_uid: nil,
      google_token: nil,
      google_refresh_token: nil,
      google_expires_at: nil,
      use_google_avatar: false
    )
      redirect_to edit_user_registration_path, notice: "Google連携を解除しました。次回からはパスワードでログインしてください。"
    else
      redirect_to edit_user_registration_path, alert: "連携解除に失敗しました。"
    end
  end

  protected

  # アカウント更新時に許可するストロングパラメータの設定
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :target_distance, :use_google_avatar ])
  end

  # 更新後のリダイレクト先
  def after_update_path_for(resource)
    edit_user_registration_path
  end

  # パスワードなしで更新する場合の対応
  def update_resource(resource, params)
    # パスワード入力がある、またはメールアドレス変更時はパスワード必須
    if params[:password].present? || (params[:email].present? && params[:email] != resource.email)
      resource.update_with_password(params)
    else
      # それ以外（名前や目標距離のみの変更）はパスワードなしで更新
      params.delete(:current_password)
      resource.update_without_password(params)
    end
  end
end
