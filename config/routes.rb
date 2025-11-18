Rails.application.routes.draw do
  # ===== 認証（Devise） =====
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  # ===== メインページ =====
  # ログイン済みユーザー向けのルート
  root "home#index"

  # ===== アプリケーション機能 =====
  # 散歩記録のCRUD機能（作成・閲覧・更新・削除）
  # ログインしているユーザーのみアクセス可能
  resources :walks

  # ログインスタンプカレンダー
  # 散歩記録をカレンダー形式で表示
  resources :login_stamps, only: [:index]

  # Google Fit連携
  # ログインユーザーのGoogle Fitデータを取得する
  get "google_fit/daily_data", to: "google_fit#daily_data"
  get "google_fit/status", to: "google_fit#status"

  # ===== システム関連 =====
  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA関連
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
