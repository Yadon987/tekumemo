require 'rails_helper'

RSpec.describe "Posts::OgpImages", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: user) }

  # 画像生成サービスをスタブ化（高速化）
  let(:dummy_image_data) { "\xFF\xD8\xFF\xE0\x00\x10JFIF" } # JPEGマジックナンバー

  before do
    allow_any_instance_of(RpgCardGeneratorService).to receive(:generate).and_return(dummy_image_data)
  end

  describe "GET /posts/:post_id/ogp_image" do
    context "投稿が存在する場合" do
      it "リダイレクトまたは成功レスポンスが返されること" do
        get post_ogp_image_path(post_record, format: :jpg)
        # 初回は画像生成後にActive Storageへリダイレクト（302）、
        # 2回目以降は既存画像へのリダイレクト（302）
        expect([ 200, 302 ]).to include(response.status)
      end

      it "キャッシュヘッダーが設定されていること" do
        get post_ogp_image_path(post_record, format: :jpg)
        expect(response.headers['Cache-Control']).to include('max-age')
        expect(response.headers['Cache-Control']).to include('public')
      end

      it "画像が生成されてActive Storageに添付されること" do
        expect {
          get post_ogp_image_path(post_record, format: :jpg)
        }.to change { post_record.reload.ogp_image.attached? }.from(false).to(true)
      end
    end

    context "投稿が存在しない場合" do
      it "404エラーが返されること" do
        get post_ogp_image_path(post_id: 99999, format: :jpg)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
