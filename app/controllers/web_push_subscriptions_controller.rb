class WebPushSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def create
    subscription = current_user.web_push_subscriptions.find_or_initialize_by(
      endpoint: subscription_params[:endpoint]
    )

    subscription.assign_attributes(
      p256dh: subscription_params.dig(:keys, :p256dh),
      auth_key: subscription_params.dig(:keys, :auth),
      user_agent: request.user_agent
    )

    if subscription.save
      head :ok
    else
      Rails.logger.error "Failed to save subscription: #{subscription.errors.full_messages.join(', ')}"
      head :unprocessable_entity
    end
  end

  private

  def subscription_params
    params.permit(:endpoint, keys: [ :p256dh, :auth ])
  end
end
