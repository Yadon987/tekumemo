# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store,
  key: "_tekumemo_session_v3",
  secure: Rails.env.production?,
  same_site: Rails.env.production? ? :none : :lax
