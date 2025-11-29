# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store,
  key: "_tekumemo_session_v2", # キーを変更して古いセッションを無効化
  secure: Rails.env.production?, # 本番環境のみSecure属性を有効化（HTTPS必須）
  same_site: :lax               # クロスサイトリクエスト（OAuthコールバック）のためにLaxを指定
