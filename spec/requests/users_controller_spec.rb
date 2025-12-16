require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /users/:id/edit" do
    context "本人の場合" do
      it "編集ページが表示されること" do
        get edit_user_path(user)
        expect(response).to have_http_status(:success)
      end
    end

    context "他人の場合" do
      it "トップページにリダイレクトされること" do
        get edit_user_path(other_user)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("権限がありません")
      end
    end
  end

  describe "PATCH /users/:id" do
    context "有効なパラメータの場合（パスワード変更なし）" do
      let(:user_params) { { name: "New Name", target_distance: 10000 } }

      it "ユーザー情報が更新されること" do
        patch user_path(user), params: { user: user_params }
        user.reload
        expect(user.name).to eq("New Name")
        expect(user.target_distance).to eq(10000)
        expect(response).to redirect_to(edit_user_path(user))
        expect(flash[:notice]).to eq("プロフィールを更新しました")
      end
    end

    context "有効なパラメータの場合（パスワード変更あり）" do
      let(:new_password) { "new_password" }
      let(:user_params) do
        {
          password: new_password,
          password_confirmation: new_password,
          current_password: user.password
        }
      end

      it "パスワードが更新されること" do
        patch user_path(user), params: { user: user_params }
        user.reload
        expect(user.valid_password?(new_password)).to be true
        expect(response).to redirect_to(edit_user_path(user))
      end
    end

    context "無効なパラメータの場合" do
      let(:user_params) { { name: "" } }

      it "更新されず、編集ページが再表示されること" do
        patch user_path(user), params: { user: user_params }
        user.reload
        expect(user.name).not_to eq("")
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "他人の情報を更新しようとした場合" do
      it "更新されず、トップページにリダイレクトされること" do
        patch user_path(other_user), params: { user: { name: "Hacked" } }
        expect(response).to redirect_to(root_path)
        other_user.reload
        expect(other_user.name).not_to eq("Hacked")
      end
    end
  end

  describe "DELETE /users/disconnect_google" do
    before do
      user.update!(
        google_uid: "12345",
        google_token: "token",
        google_refresh_token: "refresh_token",
        google_expires_at: 1.hour.from_now,
        use_google_avatar: true
      )
    end

    it "Google連携情報が削除されること" do
      delete disconnect_google_user_path(user), params: { user: { current_password: user.password } }
      user.reload
      expect(user.google_uid).to be_nil
      expect(user.google_token).to be_nil
      expect(user.google_refresh_token).to be_nil
      expect(user.google_expires_at).to be_nil
      expect(user.use_google_avatar).to be false
      expect(response).to redirect_to(edit_user_path(user))
      expect(flash[:notice]).to include("Google連携を解除しました")
    end
  end
end
