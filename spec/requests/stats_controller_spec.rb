require 'rails_helper'

RSpec.describe "Stats", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /stats" do
    it "統計ページが表示されること" do
      get stats_path
      expect(response).to have_http_status(:success)
    end

    context "データが存在する場合" do
      before do
        create(:walk, user: user, walked_on: Date.current, distance: 5.0)
        create(:walk, user: user, walked_on: 1.day.ago, distance: 3.0)
      end

      it "正常に表示されること" do
        get stats_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("統計")
      end
    end
  end

  describe "GET /stats/chart_data" do
    it "JSON形式で日次データが返されること" do
      get stats_chart_data_path(type: "daily")
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")

      json = JSON.parse(response.body)
      expect(json).to be_a(Hash)
      expect(json).to include("dates", "distances")
    end

    it "JSON形式で週次データが返されること" do
      get stats_chart_data_path(type: "weekly")
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")
    end

    it "JSON形式で月次データが返されること" do
      get stats_chart_data_path(type: "monthly")
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")
    end

    it "JSON形式で時間帯別データが返されること" do
      get stats_chart_data_path(type: "time_of_day")
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")

      json = JSON.parse(response.body)
      expect(json).to be_a(Hash)
      expect(json).to include("labels", "data")
    end

    it "無効なタイプの場合は400エラーが返されること" do
      get stats_chart_data_path(type: "invalid")
      expect(response).to have_http_status(:bad_request)
    end
  end
end
