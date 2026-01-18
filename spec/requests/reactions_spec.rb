require 'rails_helper'

RSpec.describe 'Reactions', type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let!(:post_item) { FactoryBot.create(:post, user: other_user) }

  before { sign_in user }

  describe 'POST /posts/:post_id/reactions' do
    context '有効なパラメータの場合' do
      let(:reaction_params) { { reaction: { stamp: 'thumbs_up' } } }

      it 'リアクションが作成されること' do
        expect do
          post post_reactions_path(post_item), params: reaction_params,
                                               headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        end.to change(Reaction, :count).by(1)
      end

      it 'Turbo Stream形式でレスポンスが返ること' do
        post post_reactions_path(post_item), params: reaction_params,
                                             headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        expect(response.media_type).to eq Mime[:turbo_stream]
        expect(response).to have_http_status(:success)
      end

      it 'JSON形式でリクエストすると、JSON形式でレスポンスが返ること' do
        post post_reactions_path(post_item),
             params: reaction_params,
             headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'

        json_response = JSON.parse(response.body)
        expect(json_response['reacted']).to eq(true)
        expect(json_response['count']).to eq(1)
      end
    end

    context '重複するリアクションの場合（トグル動作）' do
      before do
        FactoryBot.create(:reaction, user: user, post: post_item, stamp: 'thumbs_up')
      end

      it 'リアクションが削除されること' do
        expect do
          post post_reactions_path(post_item), params: { reaction: { stamp: 'thumbs_up' } },
                                               headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        end.to change(Reaction, :count).by(-1)
      end

      it 'JSON形式でリクエストすると、削除後のステータスがJSON形式で返ること' do
        post post_reactions_path(post_item),
             params: { reaction: { stamp: 'thumbs_up' } },
             headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'

        json_response = JSON.parse(response.body)
        expect(json_response['reacted']).to eq(false)
        expect(json_response['count']).to eq(0)
      end
    end
  end

  describe 'DELETE /posts/:post_id/reactions/:id' do
    let!(:reaction) { FactoryBot.create(:reaction, user: user, post: post_item, stamp: 'thumbs_up') }

    it 'リアクションを削除できること' do
      # ID指定での削除
      expect do
        delete post_reaction_path(post_item, reaction), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      end.to change(Reaction, :count).by(-1)
    end
  end
end
