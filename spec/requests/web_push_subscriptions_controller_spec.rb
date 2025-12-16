require 'rails_helper'

RSpec.describe "WebPushSubscriptions", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "POST /web_push_subscriptions" do
    let(:valid_params) do
      {
        endpoint: "https://fcm.googleapis.com/fcm/send/test",
        keys: {
          p256dh: "test_p256dh",
          auth: "test_auth_key"
        }
      }
    end

    context "有効なパラメータの場合" do
      it "購読情報が保存されること" do
        expect {
          post web_push_subscriptions_path, params: valid_params
        }.to change(WebPushSubscription, :count).by(1)
        expect(response).to have_http_status(:ok)
      end
    end

    context "既存の購読情報がある場合" do
      before do
        create(:web_push_subscription, user: user, endpoint: valid_params[:endpoint])
      end

      it "重複して保存されず、成功ステータスを返すこと" do
        expect {
          post web_push_subscriptions_path, params: valid_params
        }.not_to change(WebPushSubscription, :count)
        expect(response).to have_http_status(:ok)
      end
    end

    context "無効なパラメータの場合" do
      it "保存されず、エラーステータスを返すこと" do
        expect {
          post web_push_subscriptions_path, params: { endpoint: "" }
        }.not_to change(WebPushSubscription, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
