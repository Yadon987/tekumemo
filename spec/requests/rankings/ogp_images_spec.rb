require 'rails_helper'

RSpec.describe 'Rankings::OgpImages', type: :request do
  let(:user) { create(:user) }

  # 画像生成サービスをスタブ化（高速化）
  let(:dummy_image_data) { "\xFF\xD8\xFF\xE0\x00\x10JFIF" } # JPEGマジックナンバー

  before do
    sign_in user
    allow_any_instance_of(RpgCardGeneratorService).to receive(:generate).and_return(dummy_image_data)
  end

  describe 'GET /rankings/users/:id/ogp_image' do
    context 'ユーザーが存在する場合' do
      it '画像データが直接返されること' do
        get ogp_image_rankings_user_path(user, format: :jpg)
        expect(response.status).to eq(200)
        expect(response.content_type).to eq('image/jpeg')
        expect(response.body).to eq(dummy_image_data)
      end

      it 'キャッシュヘッダーが設定されていること' do
        get ogp_image_rankings_user_path(user, format: :jpg)
        expect(response.headers['Cache-Control']).to include('max-age')
      end

      it '画像が生成されてActive Storageに添付されること' do
        expect do
          get ogp_image_rankings_user_path(user, format: :jpg)
        end.to change { user.reload.ranking_ogp_image.attached? }.from(false).to(true)
      end
    end

    context 'ユーザーが存在しない場合' do
      it 'デフォルト画像へリダイレクトされること' do
        get ogp_image_rankings_user_path(id: 99_999, format: :jpg)
        expect(response).to redirect_to(ActionController::Base.helpers.image_url('icon.png'))
      end
    end
  end
end
