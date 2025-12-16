require "rails_helper"

RSpec.describe WebPushService, type: :service do
  describe ".send_notification" do
    let(:user) { create(:user) }
    let!(:subscription) { create(:web_push_subscription, user: user) }
    let(:title) { "Test Title" }
    let(:body) { "Test Body" }

    before do
      allow(WebPush).to receive(:payload_send)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("VAPID_PUBLIC_KEY").and_return("public_key")
      allow(ENV).to receive(:[]).with("VAPID_PRIVATE_KEY").and_return("private_key")
    end

    context "正常系" do
      it "WebPush.payload_sendを呼び出すこと" do
        described_class.send_notification(user, title: title, body: body)

        expect(WebPush).to have_received(:payload_send).with(
          hash_including(
            message: include(title, body),
            endpoint: subscription.endpoint,
            p256dh: subscription.p256dh,
            auth: subscription.auth_key
          )
        )
      end
    end

    context "購読情報がない場合" do
      let(:user_without_sub) { create(:user) }

      it "何も送信しないこと" do
        described_class.send_notification(user_without_sub, title: title, body: body)
        expect(WebPush).not_to have_received(:payload_send)
      end
    end

    context "購読が無効な場合（WebPush::InvalidSubscription例外）" do
      before do
        # WebPush::InvalidSubscriptionはinitializeでresponse.bodyを参照するため、モックが必要
        response = double("Response", body: "Invalid subscription")
        allow(WebPush).to receive(:payload_send).and_raise(WebPush::InvalidSubscription.new(response, "host"))
      end

      it "購読情報を削除すること" do
        expect(WebPushSubscription.count).to eq(1)
        described_class.send_notification(user, title: title, body: body)
        expect(WebPushSubscription.count).to eq(0)
      end
    end

    context "その他のエラーが発生した場合" do
      before do
        allow(WebPush).to receive(:payload_send).and_raise(StandardError.new("Unknown error"))
      end

      it "エラーログを出力し、処理を継続すること（例外を再スローしない）" do
        expect(Rails.logger).to receive(:error).with(/Failed to send push notification/)
        expect {
          described_class.send_notification(user, title: title, body: body)
        }.not_to raise_error
      end
    end
  end
end
