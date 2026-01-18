require 'rails_helper'

RSpec.describe 'Walks', type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:my_walk) { FactoryBot.create(:walk, user: user, walked_on: Date.current) }
  let(:other_walk) { FactoryBot.create(:walk, user: other_user, walked_on: Date.current) }

  describe 'GET /walks/new' do
    context 'ログインしている場合' do
      before { sign_in user }

      it '新規作成ページにアクセスできること' do
        get new_walk_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get new_walk_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /walks' do
    before { sign_in user }

    context '有効なパラメータの場合' do
      let(:walk_params) do
        { walk: { walked_on: 1.week.from_now.to_date, kilometers: 5.0, minutes: 60, steps: 5000, calories: 300 } }
      end

      it '散歩記録が作成されること' do
        expect do
          post walks_path, params: walk_params
        end.to change(Walk, :count).by(1)
      end

      it '詳細ページ（または一覧）にリダイレクトされること' do
        post walks_path, params: walk_params
        expect(response).to redirect_to(walks_path)
      end
    end

    context '無効なパラメータの場合' do
      let(:invalid_params) { { walk: { walked_on: nil, kilometers: nil } } }

      it '散歩記録が作成されないこと' do
        expect do
          post walks_path, params: invalid_params
        end.not_to change(Walk, :count)
      end
    end
  end

  describe 'GET /walks/:id/edit' do
    before { sign_in user }

    context '自分の記録の場合' do
      it '編集ページにアクセスできること' do
        get edit_walk_path(my_walk)
        expect(response).to have_http_status(:success)
      end
    end

    context '他人の記録の場合' do
      it 'アクセスできないこと（リダイレクトまたはエラー）' do
        get edit_walk_path(other_walk)
        expect(response).not_to have_http_status(:success)
        # 実装によりリダイレクト先が異なるため、ステータスコードで判定
      end
    end
  end

  describe 'PATCH /walks/:id' do
    before { sign_in user }

    context '自分の記録の場合' do
      let(:update_params) { { walk: { kilometers: 10.0 } } }

      it '更新できること' do
        patch walk_path(my_walk), params: update_params
        expect(my_walk.reload.kilometers).to eq 10.0
      end
    end

    context '他人の記録の場合' do
      let(:update_params) { { walk: { kilometers: 100.0 } } }

      it '更新できないこと' do
        patch walk_path(other_walk), params: update_params
        expect(other_walk.reload.kilometers).not_to eq 100.0
      end
    end
  end

  describe 'DELETE /walks/:id' do
    before { sign_in user }

    context '自分の記録の場合' do
      it '削除できること' do
        my_walk # 事前に作成
        expect do
          delete walk_path(my_walk)
        end.to change(Walk, :count).by(-1)
      end
    end

    context '他人の記録の場合' do
      before { other_walk } # 事前に作成

      it '削除できないこと' do
        expect do
          delete walk_path(other_walk)
        end.not_to change(Walk, :count)
      end
    end
  end
end
