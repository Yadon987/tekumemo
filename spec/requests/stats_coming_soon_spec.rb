require 'rails_helper'

RSpec.describe "StatsComingSoons", type: :request do
  let(:user) { FactoryBot.create(:user) }

  before do
    sign_in user
  end

  describe "GET /index" do
    it "returns http success" do
      get stats_path
      expect(response).to have_http_status(:success)
    end
  end
end
