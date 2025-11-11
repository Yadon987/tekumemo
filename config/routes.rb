Rails.application.routes.draw do

  # === 認証 ===
  devise_for :users

  # === メインページ ===
  root "home#index"

  # === アプリケーション機能 ===
  
  # === システム関連 ===
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
