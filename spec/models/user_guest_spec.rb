require 'rails_helper'

RSpec.describe User, type: :model do
  describe '.create_portfolio_guest' do
    # Cloudinaryの削除コールをモック（テスト環境での外部通信防止）
    before do
      allow(Cloudinary::Uploader).to receive(:destroy).and_return({ "result" => "ok" })

      # テストデータの強制お掃除（DB汚染対策）
      Reaction.delete_all
      Notification.delete_all
      WebPushSubscription.delete_all
      UserAchievement.delete_all
      Post.delete_all
      Walk.delete_all
      User.delete_all
    end

    context 'when admin user exists' do
      let!(:admin_user) { FactoryBot.create(:user, :admin, target_distance: 8000) }

      before do
        # 管理者用のデータ作成
        # 3ヶ月以内の散歩
        FactoryBot.create(:walk, user: admin_user, walked_on: 1.day.ago, distance: 5)
        FactoryBot.create(:walk, user: admin_user, walked_on: 2.months.ago, distance: 4)
        # 3ヶ月より前の散歩（コピーされないはず）
        FactoryBot.create(:walk, user: admin_user, walked_on: 4.months.ago, distance: 3)

        # 投稿
        FactoryBot.create(:post, user: admin_user, created_at: 1.day.ago)

        # 実績
        achievement = FactoryBot.create(:achievement)
        UserAchievement.create(user: admin_user, achievement: achievement)
      end

      it 'creates a guest user with copied data' do
        expect {
          User.create_portfolio_guest
        }.to change(User, :count).by(1)

        guest = User.last
        expect(guest.role).to eq 'guest'
        expect(guest.name).to eq 'ゲストユーザー'
        expect(guest.target_distance).to eq admin_user.target_distance # 管理者の設定を継承

        # 散歩記録のコピー確認
        expect(guest.walks.count).to eq 2
        distances = guest.walks.pluck(:distance)
        expect(distances).to include(5, 4)
        expect(distances).not_to include(3)

        # 投稿のコピー確認
        expect(guest.posts.count).to eq 1

        # 実績のコピー確認
        expect(guest.user_achievements.count).to eq 1
      end
    end

    context 'when no admin user exists' do
      # トランザクションでロールバックされるため、明示的な削除は不要
      # ただし、念のため管理者だけはいないことを保証するなどしてもよいが、
      # ここではシンプルに何も作らない状態でテストする

      it 'creates a fallback guest user' do
        guest = User.create_portfolio_guest
        expect(guest.role).to eq 'guest'
        expect(guest.persisted?).to be true
        expect(guest.walks.count).to eq 0
      end
    end

    context 'cleanup logic' do
      it 'removes guests created more than 24 hours ago' do
        old_guest = FactoryBot.create(:user, role: :guest, created_at: 25.hours.ago)
        new_guest = FactoryBot.create(:user, role: :guest, created_at: 1.hour.ago)

        User.create_portfolio_guest

        expect(User.exists?(old_guest.id)).to be false
        expect(User.exists?(new_guest.id)).to be true
      end
    end
  end
end
