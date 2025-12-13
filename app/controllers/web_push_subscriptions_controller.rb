class WebPushSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:create] # JSONリクエストのためCSRFトークン検証をスキップ（ヘッダーで検証済み）

  def create
    subscription = current_user.web_push_subscriptions.find_or_initialize_by(
      endpoint: params[:endpoint]
    )

    subscription.update!(
      p256dh: params[:keys][:p256dh],
      auth_key: params[:keys][:auth],
      user_agent: request.user_agent
    )

    head :ok
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to save subscription: #{e.message}"
    head :unprocessable_entity
  end
end
