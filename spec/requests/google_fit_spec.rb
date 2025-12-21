require 'rails_helper'

RSpec.describe "GoogleFit", type: :request do
  # テスト用ユーザーの作成
  let(:user) { FactoryBot.create(:user) }



  describe "GET /google_fit/status" do
    before { sign_in user }

    context "連携済みの場合" do
      before do
        user.update(google_token: "token", google_refresh_token: "refresh_token", google_expires_at: 1.hour.from_now)
      end

      it "connected: true とメールアドレスが返ること" do
        get google_fit_status_path

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["connected"]).to be true
        expect(json["email"]).to eq(user.email)
      end
    end

    context "未連携の場合" do
      before do
        user.update(google_token: nil)
      end

      it "connected: false が返ること" do
        get google_fit_status_path

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["connected"]).to be false
      end
    end
  end
end
