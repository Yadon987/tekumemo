Rails.application.routes.draw do
  get "stats_coming_soon/index"
  # =====  # Deviseの設定（コントローラーをカスタマイズ）
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations",
    sessions: "users/sessions",
    passwords: "users/passwords"
  }

  # ===== メインページ =====
  # ログイン済みユーザー向けのルート
  root "home#index"

  # ===== アプリケーション機能 =====
  # 散歩記録のCRUD機能（作成・閲覧・更新・削除）
  # ログインしているユーザーのみアクセス可能
  resources :walks do
    collection do
      post :import_google_fit
    end
  end

  # ログインスタンプカレンダー
  # 散歩記録をカレンダー形式で表示
  resources :login_stamps, only: [ :index ]
  resources :achievements, only: [ :index ]
  resources :rankings, only: [ :index ]
  namespace :rankings do
    resources :users, only: [] do
      member do
        get :ogp_image, to: "ogp_images#show", defaults: { format: :jpg }, as: :ogp_image
      end
    end
  end

  # 統計機能
  get "stats", to: "stats#index", as: :stats
  get "stats/chart_data", to: "stats#chart_data", as: :stats_chart_data

  # Google Fit連携
  # ログインユーザーのGoogle Fitデータを取得する
  get "google_fit/status", to: "google_fit#status"
  get "google_fit/daily_data", to: "google_fit#daily_data"

  # SNS機能
  resources :posts, only: [ :index, :show, :create, :destroy ] do
    collection do
      # 自分の投稿履歴を表示
      get "mine"
    end

    resource :ogp_image, only: [ :show ], module: :posts, defaults: { format: :jpg }
    resources :reactions, only: [ :create, :destroy ]
  end

  # 通知機能
  resources :notifications, only: [ :index ] do
    member do
      patch :mark_as_read  # 個別既読
    end
    collection do
      patch :mark_all_as_read  # 一括既読
    end
  end

  # Web Push通知購読
  resources :web_push_subscriptions, only: [ :create ]

  # ユーザープロフィール編集
  resources :users, only: [] do
    member do
      delete :disconnect_google
    end
  end

  # ===== 管理者機能 =====
  namespace :admin do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"

    resources :users, only: [ :index, :destroy ]
    # ゲストデータ掃除
    post "cleanup_guests", to: "dashboard#cleanup_guests"

    resources :posts, only: [ :index, :show, :destroy ]
    resources :walks, only: [ :index, :show, :destroy ]
    resources :announcements do
      member do
        patch :publish    # 公開
        patch :unpublish  # 非公開
      end
    end
  end

  # ===== システム関連 =====
  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check
  # Deviseのスコープ内で独自アクションを定義
  devise_scope :user do
    # メールアドレス変更確認画面
    get "users/confirm_email_change", to: "users/omniauth_callbacks#confirm_email_change", as: :confirm_email_change_users
    # メールアドレス更新＆連携実行
    post "users/update_email_and_connect", to: "users/omniauth_callbacks#update_email_and_connect", as: :update_email_and_connect_users
    # アップロード画像の削除
    delete "users/uploaded_avatar", to: "users/registrations#delete_uploaded_avatar", as: :delete_user_uploaded_avatar

    # ゲストログイン
    post "users/guest_sign_in", to: "users/sessions#new_guest", as: :users_guest_sign_in
  end

  # ===== 静的ページ =====
  get "privacy", to: "static_pages#privacy"

  # PWA関連
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
