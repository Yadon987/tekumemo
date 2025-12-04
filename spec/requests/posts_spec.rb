require 'rails_helper'

RSpec.describe "Posts", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let!(:my_post) { FactoryBot.create(:post, user: user, body: "自分の投稿") }
  let!(:other_post) { FactoryBot.create(:post, user: other_user, body: "他人の投稿") }

  describe "GET /posts" do
    context "ログインしている場合" do
      before { sign_in user }

      it "投稿一覧ページにアクセスできること" do
        get posts_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("みんなの足跡")
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされること" do
        get posts_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /posts" do
    before { sign_in user }

    context "有効なパラメータの場合" do
      let(:post_params) { { post: { body: "新しい投稿", weather: "sunny", feeling: "great" } } }

      it "投稿が作成されること" do
        expect {
          post posts_path, params: post_params
        }.to change(Post, :count).by(1)
      end

      it "投稿一覧ページにリダイレクトされること" do
        post posts_path, params: post_params
        expect(response).to redirect_to(posts_path)
      end
    end

    context "無効なパラメータの場合" do
      let(:invalid_params) { { post: { body: "", weather: nil, feeling: nil } } }

      it "投稿が作成されないこと" do
        expect {
          post posts_path, params: invalid_params
        }.not_to change(Post, :count)
      end
    end
  end

  describe "DELETE /posts/:id" do
    before { sign_in user }

    context "自分の投稿の場合" do
      it "投稿を削除できること" do
        expect {
          delete post_path(my_post)
        }.to change(Post, :count).by(-1)
      end
    end

    context "他人の投稿の場合" do
      it "投稿を削除できないこと" do
        expect {
          delete post_path(other_post)
        }.not_to change(Post, :count)
      end

      it "ルートページなどにリダイレクトされる、またはエラーになること" do
        delete post_path(other_post)
        # 権限がない場合はリダイレクトされるか403/404エラーになるはず
        expect(response).not_to have_http_status(:success)
      end
    end
  end
end
