require 'rails_helper'

RSpec.describe 'Achievements', type: :request do
  let(:user) { FactoryBot.create(:user) }

  describe 'GET /index' do
    context 'ログインしている場合' do
      before do
        sign_in user
      end

      it '正常にレスポンスが返ること' do
        get achievements_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'ログインしていない場合' do
      it 'ログイン画面にリダイレクトされること' do
        get achievements_path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
