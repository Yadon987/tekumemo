require "rails_helper"

RSpec.describe User, type: :model do
  describe "バリデーション" do
    it "有効な属性であれば有効であること" do
      user = User.new(name: "テストユーザー", email: "test@example.com", password: "password", target_distance: 5000)
      expect(user).to be_valid
    end

    it "ユーザー名がない場合は無効であること" do
      user = User.new(name: nil, email: "test@example.com", password: "password", target_distance: 5000)
      user.valid?
      expect(user.errors[:name]).to include("を入力してください")
    end

    it "目標距離がない場合は無効であること" do
      user = User.new(name: "テストユーザー", email: "test@example.com", password: "password", target_distance: nil)
      user.valid?
      expect(user.errors[:target_distance]).to include("を入力してください")
    end

    it "目標距離が100,000より大きい場合は無効であること" do
      user = User.new(name: "テストユーザー", email: "test@example.com", password: "password", target_distance: 100_001)
      user.valid?
      expect(user.errors[:target_distance]).to include("は100000以下の値にしてください")
    end
  end

  describe ".from_omniauth" do
    # OmniAuthのモックデータを作成
    # 実際のGoogle認証の代わりに、このハッシュデータを使用します
    let(:auth_hash) do
      OmniAuth::AuthHash.new({
        provider: "google_oauth2",
        uid: "123456789",
        info: {
          email: "test@example.com",
          image: "https://example.com/avatar.jpg"
        },
        credentials: {
          token: "mock_token",
          refresh_token: "mock_refresh_token",
          expires_at: Time.now.to_i + 3600
        }
      })
    end

    context "ユーザーが既に存在する場合（Google UIDで一致）" do
      it "そのユーザーを返し、Google認証情報を更新すること" do
        # 事前にユーザーを作成
        user = User.create!(
          name: "既存ユーザー",
          email: "other@example.com", # メールアドレスは異なっていてもUIDで紐付く
          password: "password123",
          google_uid: "123456789" # auth_hashと同じUID
        )

        # メソッド実行
        result_user = User.from_omniauth(auth_hash)

        # 検証
        expect(result_user).to eq(user) # 同じユーザーオブジェクトが返されるか
        expect(result_user.google_token).to eq("mock_token") # トークンが更新されているか
        expect(result_user.avatar_url).to eq("https://example.com/avatar.jpg") # アバター画像が更新されているか
      end
    end

    context "ユーザーが存在しない場合" do
      it "新しいユーザーを作成せず、nilを返すこと" do
        # ユーザー数が増えないことを検証
        expect {
          result = User.from_omniauth(auth_hash)
          expect(result).to be_nil
        }.not_to change(User, :count)
      end
    end
  end
end
