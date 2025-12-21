class GoogleFitController < ApplicationController
  # ログインしていないユーザーはアクセスできないようにする
  before_action :authenticate_user!



  # Google Fitとの連携状態を確認する
  # GET /google_fit/status
  def status
    if current_user.google_token_valid?
      render json: {
        connected: true,
        email: current_user.email
      }
    else
      render json: {
        connected: false
      }
    end
  end
end
