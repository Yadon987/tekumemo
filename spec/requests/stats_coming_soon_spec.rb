require 'rails_helper'

RSpec.describe "StatsComingSoons", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/stats_coming_soon/index"
      expect(response).to have_http_status(:success)
    end
  end
end
