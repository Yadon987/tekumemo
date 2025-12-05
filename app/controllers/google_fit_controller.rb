class GoogleFitController < ApplicationController
  # ログインしていないユーザーはアクセスできないようにする
  before_action :authenticate_user!

  # 指定した日付のGoogle Fitデータを取得する
  # GET /google_fit/daily_data?date=2025-01-15
  def daily_data
    # リクエストパラメータから日付を取得（デフォルトは今日）
    date = params[:date] ? Date.parse(params[:date]) : Date.today

    # ユーザーがGoogle認証済みかチェック
    unless current_user.google_token_valid?
      render json: {
        error: "Google Fitと連携されていません。連携してください。"
      }, status: :unauthorized
      return
    end

    # Google Fit APIからデータを取得
    service = GoogleFitService.new(current_user)
    data = service.fetch_daily_data(date)

    if data
      # 取得成功: データをJSON形式で返す
      render json: {
        date: date,
        steps: data[:steps],
        distance: data[:distance],
        duration: data[:duration],
        calories: data[:calories]
      }
    else
      # 取得失敗: エラーメッセージを返す
      render json: {
        error: "Google Fitからデータを取得できませんでした。"
      }, status: :unprocessable_entity
    end
  rescue Date::Error
    # 日付のパースに失敗した場合
    render json: {
      error: "無効な日付形式です。"
    }, status: :bad_request
  rescue StandardError => e
    # Google Fit API呼び出しやトークン期限切れなどのエラー
    Rails.logger.error "Google Fit API Error: #{e.class} - #{e.message}"
    render json: {
      error: "Google Fitとの連携が切れています。設定画面から再度連携してください。"
    }, status: :unauthorized
  end

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
