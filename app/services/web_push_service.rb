class WebPushService
  def self.send_notification(user, title:, body:, url: "/", icon: "/icon-192.png")
    subscriptions = user.web_push_subscriptions

    if subscriptions.empty?
      Rails.logger.info "No push subscriptions found for user #{user.id}"
      return
    end

    payload = {
      title: title,
      body: body,
      icon: icon,
      url: url
    }.to_json

    subscriptions.find_each do |subscription|
      begin
        WebPush.payload_send(
          message: payload,
          endpoint: subscription.endpoint,
          p256dh: subscription.p256dh,
          auth: subscription.auth_key,
          vapid: {
            subject: ENV["VAPID_SUBJECT"] || "mailto:admin@example.com",
            public_key: ENV["VAPID_PUBLIC_KEY"],
            private_key: ENV["VAPID_PRIVATE_KEY"]
          }
        )
      rescue WebPush::InvalidSubscription => e
        # 購読が無効になっている場合は削除
        Rails.logger.info "Removing invalid subscription for user #{user.id}: #{e.message}"
        subscription.destroy
      rescue StandardError => e
        Rails.logger.error "Failed to send push notification to user #{user.id}: #{e.message}"
      end
    end
  end
end
