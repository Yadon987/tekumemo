require "rails_helper"

RSpec.describe User, type: :model do
  describe "バリデーション" do
    it "有効な属性であれば有効であること" do
      user = FactoryBot.build(:user)
      expect(user).to be_valid
    end

    it "ユーザー名がない場合は無効であること" do
      user = FactoryBot.build(:user, name: nil)
      user.valid?
      expect(user.errors[:name]).to include("を入力してください")
    end

    it "目標距離がない場合は無効であること" do
      user = FactoryBot.build(:user, target_distance: nil)
      user.valid?
      expect(user.errors[:target_distance]).to include("を入力してください")
    end

    it "目標距離が100,000より大きい場合は無効であること" do
      user = FactoryBot.build(:user, target_distance: 100_001)
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
        user = FactoryBot.create(:user,
          name: "既存ユーザー",
          email: "other@example.com",
          google_uid: "123456789"
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

  describe "#consecutive_walk_days" do
    let(:user) { FactoryBot.create(:user) }

    context "記録がない場合" do
      it "0を返すこと" do
        expect(user.consecutive_walk_days).to eq 0
      end
    end

    context "今日記録がある場合" do
      before { FactoryBot.create(:walk, user: user, walked_on: Date.current) }

      it "1を返すこと" do
        expect(user.consecutive_walk_days).to eq 1
      end
    end

    context "今日と昨日記録がある場合" do
      before do
        FactoryBot.create(:walk, user: user, walked_on: Date.current)
        FactoryBot.create(:walk, user: user, walked_on: 1.day.ago.to_date)
      end

      it "2を返すこと" do
        expect(user.consecutive_walk_days).to eq 2
      end
    end

    context "連続が途切れている場合" do
      before do
        FactoryBot.create(:walk, user: user, walked_on: Date.current)
        # 昨日はなし
        FactoryBot.create(:walk, user: user, walked_on: 2.days.ago.to_date)
      end

      it "1を返すこと" do
        expect(user.consecutive_walk_days).to eq 1
      end
    end
  end

  describe ".ranking" do
    let!(:user_a) { FactoryBot.create(:user, name: "User A") }
    let!(:user_b) { FactoryBot.create(:user, name: "User B") }
    let!(:user_c) { FactoryBot.create(:user, name: "User C") }

    before do
      # User A: 今日 5km, 昨日 3km, 先月 10km
      FactoryBot.create(:walk, user: user_a, walked_on: Date.current, distance: 5.0)
      FactoryBot.create(:walk, user: user_a, walked_on: 1.day.ago, distance: 3.0)
      FactoryBot.create(:walk, user: user_a, walked_on: 1.month.ago, distance: 10.0)

      # User B: 今日 10km
      FactoryBot.create(:walk, user: user_b, walked_on: Date.current, distance: 10.0)

      # User C: 昨日 20km (今日はなし)
      FactoryBot.create(:walk, user: user_c, walked_on: 1.day.ago, distance: 20.0)
    end

    context "期間: weekly (今週)" do
      around do |example|
        # 2025-12-24 (水) に固定してテスト実行
        travel_to(Time.zone.parse("2025-12-24 12:00:00")) do
          example.run
        end
      end

      it "今週の記録が集計され、距離順に並ぶこと" do
        # User A: 今日 5km + 昨日 3km = 8km
        # User B: 今日 10km
        # User C: 昨日 20km

        ranking = User.ranking(period: "weekly")

        expect(ranking.length).to eq 3
        expect(ranking[0].id).to eq user_c.id # 20km
        expect(ranking[0].total_distance).to eq 20.0
        expect(ranking[1].id).to eq user_b.id # 10km
        expect(ranking[1].total_distance).to eq 10.0
        expect(ranking[2].id).to eq user_a.id # 8km
        expect(ranking[2].total_distance).to eq 8.0
      end
    end

    context "期間: monthly (今月)" do
      it "今月の記録が集計され、距離順に並ぶこと" do
        # 既存のデータをクリア
        Walk.delete_all

        current_month = Date.current.beginning_of_month
        last_month = 1.month.ago.beginning_of_month

        # User A: 今月5km, 先月10km
        FactoryBot.create(:walk, user: user_a, walked_on: current_month + 1.day, distance: 5.0)
        FactoryBot.create(:walk, user: user_a, walked_on: last_month + 1.day, distance: 10.0)

        # User B: 今月10km
        FactoryBot.create(:walk, user: user_b, walked_on: current_month + 2.days, distance: 10.0)

        ranking = User.ranking(period: "monthly")

        expect(ranking.length).to eq 2
        expect(ranking[0].id).to eq user_b.id # 10km
        expect(ranking[1].id).to eq user_a.id # 5km
      end
    end

    context "期間: yearly (今年)" do
      it "今年の記録が集計され、距離順に並ぶこと" do
        Walk.delete_all
        current_year = Date.current.beginning_of_year
        last_year = 1.year.ago.beginning_of_year

        # User A: 今年5km, 去年10km
        FactoryBot.create(:walk, user: user_a, walked_on: current_year + 1.day, distance: 5.0)
        FactoryBot.create(:walk, user: user_a, walked_on: last_year + 1.day, distance: 10.0)

        # User B: 今年10km
        FactoryBot.create(:walk, user: user_b, walked_on: current_year + 2.days, distance: 10.0)

        ranking = User.ranking(period: "yearly")

        expect(ranking.length).to eq 2
        expect(ranking[0].id).to eq user_b.id # 10km
        expect(ranking[1].id).to eq user_a.id # 5km
      end
    end
  end

  describe "#display_avatar_url" do
    let(:user) { FactoryBot.create(:user) }

    context "avatar_type: default" do
      before { user.update(avatar_type: :default) }
      it "nilを返すこと" do
        expect(user.display_avatar_url).to be_nil
      end
    end

    context "avatar_type: google" do
      before do
        user.update(avatar_type: :google, avatar_url: "https://example.com/google.jpg")
      end
      it "googleのURLを返すこと" do
        expect(user.display_avatar_url).to eq "https://example.com/google.jpg"
      end
    end

    context "avatar_type: uploaded" do
      before do
        user.update(avatar_type: :uploaded)
        user.uploaded_avatar.attach(io: File.open(Rails.root.join("spec/fixtures/files/avatar.jpg")), filename: "avatar.jpg", content_type: "image/jpeg")
      end
      it "アップロードされた画像を返すこと" do
        expect(user.display_avatar_url).to be_attached
      end
    end
  end
end
