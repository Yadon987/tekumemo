class ApplicationController < ActionController::Base
  # モダンブラウザのみ許可
  allow_browser versions: :modern

  # 全アクションの前に認証をチェック
  before_action :authenticate_user!

  # Deviseのパラメータ許可設定
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # Deviseで許可する追加パラメータ
  def configure_permitted_parameters
    # サインアップ時に追加フィールドを許可する場合
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])

    # アカウント更新時に追加フィールドを許可する場合
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end
  # ログアウト後のリダイレクト先を指定
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
