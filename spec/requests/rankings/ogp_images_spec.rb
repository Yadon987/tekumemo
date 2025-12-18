require 'rails_helper'

RSpec.describe "Rankings::OgpImages", type: :request do
  let(:user) { create(:user) }

  # 画像生成サービスをスタブ化（高速化）
  let(:dummy_image_data) { "\xFF\xD8\xFF\xE0\x00\x10JFIF" } # JPEGマジックナンバー

  before do
    allow_any_instance_of(RpgCardGeneratorService).to receive(:generate).and_return(dummy_image_data)
  end

  describe "GET /rankings/users/:id/ogp_image" do
    context "ユーザーが存在する場合" do
      it "リダイレクトまたは成功レスポンスが返されること" do
        get ogp_image_rankings_user_path(user, format: :jpg)
        # 初回は画像生成後にActive Storageへリダイレクト（302）、
        # 2回目以降は既存画像へのリダイレクト（302）
        expect([ 200, 302 ]).to include(response.status)
      end

      it "キャッシュヘッダーが設定されていること" do
        get ogp_image_rankings_user_path(user, format: :jpg)
        expect(response.headers['Cache-Control']).to include('max-age')
        expect(response.headers['Cache-Control']).to include('public')
      end

      it "画像が生成されてActive Storageに添付されること" do
        expect {
          get ogp_image_rankings_user_path(user, format: :jpg)
        }.to change { user.reload.ranking_ogp_image.attached? }.from(false).to(true)
      end
    end

    context "ユーザーが存在しない場合" do
      it "404エラーが返されること" do
        get ogp_image_rankings_user_path(id: 99999, format: :jpg)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
