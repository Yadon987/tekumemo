require 'rails_helper'

RSpec.describe "Users::OmniauthCallbacks", type: :request do
  describe "POST /users/auth/google_oauth2/callback" do
    let(:user) { FactoryBot.create(:user) }

    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
        provider: "google_oauth2",
        uid: "123456789",
        info: {
          email: user.email,
          image: "http://example.com/avatar.jpg"
        },
        credentials: {
          token: "mock_token",
          refresh_token: "mock_refresh_token",
          expires_at: Time.now.to_i + 3600
        }
      })
    end

    after do
      OmniAuth.config.mock_auth[:google_oauth2] = nil
    end

    context "既存ユーザーがGoogleログインした場合" do
      before do
        # ユーザーを事前に連携状態にしておく（必須ではないが、ログインフローを確認するため）
        user.update!(google_uid: "123456789")
      end

      it "ログインに成功し、remember_meトークンがCookieにセットされること" do
        # OmniAuthのコールバックURLにPOSTリクエスト（Deviseの仕様上、GET/POSTどちらでも受け付けるが、テストではGETでコールバックを模倣することが多い。
        # ただし、Rails 7 + Turboの環境ではPOSTが推奨されることもあるが、OmniAuthのcallback自体はGETで戻ってくることが多い。
        # ここではDeviseのルーティングに合わせてリクエストを送る。

        get user_google_oauth2_omniauth_callback_path

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include("Google アカウントによる認証に成功しました。")

        # remember_user_token クッキーがセットされていることを確認
        # クッキー名はデフォルトで "remember_user_token" だが、Wardenの設定による
        expect(cookies['remember_user_token']).to be_present
      end
    end

    context "未連携のGoogleアカウントでログインしようとした場合" do
      let(:new_email) { "new_google@example.com" }

      before do
        OmniAuth.config.mock_auth[:google_oauth2].info.email = new_email
      end

      it "ログインできず、ログイン画面にリダイレクトされること" do
        expect {
          get user_google_oauth2_omniauth_callback_path
        }.not_to change(User, :count)

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to include("このGoogleアカウントは連携されていません")
      end
    end
  end
end
