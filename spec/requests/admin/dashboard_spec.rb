require 'rails_helper'

RSpec.describe "Admin::Dashboard", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:general_user) { create(:user, :general) }

  describe "GET /admin/dashboard" do
    context "管理者ユーザーの場合" do
      before { sign_in admin_user }

      it "ダッシュボードにアクセスできること" do
        get admin_root_path
        expect(response).to have_http_status(:success)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in general_user }

      it "ルートパスにリダイレクトされること" do
        get admin_root_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq "管理者権限が必要です。"
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされること" do
        get admin_root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
