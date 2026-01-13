require 'rails_helper'

RSpec.describe 'LoginStamps', type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET /login_stamps' do
    it 'スタンプカードページが表示されること' do
      get login_stamps_path
      expect(response).to have_http_status(:success)
    end
  end
end
