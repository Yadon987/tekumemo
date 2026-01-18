require 'rails_helper'

RSpec.describe 'Home', type: :request do
  describe 'GET /' do
    context 'ログインしていない場合' do
      it 'トップページ（LP）が表示されること' do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('てくメモ')
      end
    end

    context 'ログインしている場合' do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      it 'ダッシュボードが表示されること' do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('今日の散歩')
      end
    end
  end
end
