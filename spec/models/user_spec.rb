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

    context "期間: daily (今日)" do
      it "今日の記録のみが集計され、距離順に並ぶこと" do
        ranking = User.ranking(period: 'daily')

        # User B (10km) -> User A (5km)。User Cは今日歩いていないので含まれない
        expect(ranking.length).to eq 2
        expect(ranking[0].id).to eq user_b.id
        expect(ranking[0].total_distance).to eq 10.0
        expect(ranking[1].id).to eq user_a.id
        expect(ranking[1].total_distance).to eq 5.0
      end
    end

    context "期間: monthly (今月)" do
      it "今月の記録が集計され、距離順に並ぶこと" do
        # 前提: 1.day.ago が今月であること（月初1日の場合はテストが落ちる可能性があるが、Timecop等は使わず簡易的に）
        # 安全のため、1.day.ago が先月になる場合（1日）は考慮が必要だが、
        # ここでは「今日」と「昨日」が同じ月であると仮定するか、
        # 明示的に日付を指定する方が良い。

        # テストデータを再設定（日付を固定）
        Walk.delete_all
        current_month = Time.current.beginning_of_month
        last_month = 1.month.ago.beginning_of_month

        # User A: 今月5km, 先月10km
        FactoryBot.create(:walk, user: user_a, walked_on: current_month + 1.day, distance: 5.0)
        FactoryBot.create(:walk, user: user_a, walked_on: last_month + 1.day, distance: 10.0)

        # User B: 今月10km
        FactoryBot.create(:walk, user: user_b, walked_on: current_month + 2.days, distance: 10.0)

        ranking = User.ranking(period: 'monthly')

        expect(ranking.length).to eq 2
        expect(ranking[0].id).to eq user_b.id # 10km
        expect(ranking[1].id).to eq user_a.id # 5km
      end
    end

    context "期間: yearly (今年)" do
      it "今年の記録が集計され、距離順に並ぶこと" do
        Walk.delete_all
        current_year = Time.current.beginning_of_year
        last_year = 1.year.ago.beginning_of_year

        # User A: 今年5km, 去年10km
        FactoryBot.create(:walk, user: user_a, walked_on: current_year + 1.day, distance: 5.0)
        FactoryBot.create(:walk, user: user_a, walked_on: last_year + 1.day, distance: 10.0)

        # User B: 今年10km
        FactoryBot.create(:walk, user: user_b, walked_on: current_year + 2.days, distance: 10.0)

        ranking = User.ranking(period: 'yearly')

        expect(ranking.length).to eq 2
        expect(ranking[0].id).to eq user_b.id # 10km
        expect(ranking[1].id).to eq user_a.id # 5km
      end
    end
  end
end
