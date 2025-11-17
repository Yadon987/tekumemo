class ApplicationController < ActionController::Base
  # モダンブラウザのみ許可（webp, web push, badges, import maps, CSS nesting, CSS :has対応）
  allow_browser versions: :modern

  # 全アクションの前に認証をチェック
  before_action :authenticate_user!

  # Deviseのパラメータ許可設定（必要に応じて追加）
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # Deviseで許可する追加パラメータ
  def configure_permitted_parameters
    # サインアップ時に追加フィールドを許可する場合
    # devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :profile_image])

    # アカウント更新時に追加フィールドを許可する場合
    # devise_parameter_sanitizer.permit(:account_update, keys: [:username, :profile_image])
  end
end
