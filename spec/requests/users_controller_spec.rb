require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in user
  end

  describe "DELETE /users/disconnect_google" do
    before do
      user.update!(
        google_uid: "12345",
        google_token: "token",
        google_refresh_token: "refresh_token",
        google_expires_at: 1.hour.from_now,
        avatar_type: :google
      )
    end

    it "Google連携情報が削除されること" do
      delete disconnect_google_user_path(user), params: { user: { current_password: user.password } }
      user.reload
      expect(user.google_uid).to be_nil
      expect(user.google_token).to be_nil
      expect(user.google_refresh_token).to be_nil
      expect(user.google_expires_at).to be_nil
      expect(user.default?).to be true
      expect(response).to redirect_to(edit_user_registration_path)
      expect(flash[:notice]).to include("Google連携を解除しました")
    end
  end
end
