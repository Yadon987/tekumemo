require 'rails_helper'

RSpec.describe "Rankings", type: :request do
  let(:user) { FactoryBot.create(:user) }

  describe "GET /rankings" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "ランキングページにアクセスできること" do
        get rankings_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("ランキング")
      end

      it "期間パラメータ(monthly)を指定してもアクセスできること" do
        get rankings_path(period: 'monthly')
        expect(response).to have_http_status(:success)
      end

      it "期間パラメータ(yearly)を指定してもアクセスできること" do
        get rankings_path(period: 'yearly')
        expect(response).to have_http_status(:success)
      end

      it "期間パラメータ(weekly)を指定してもアクセスできること" do
        get rankings_path(period: 'weekly')
        expect(response).to have_http_status(:success)
      end
    end

    context "ログインしていない場合" do
      it "ランキングページにアクセスできること" do
        get rankings_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
