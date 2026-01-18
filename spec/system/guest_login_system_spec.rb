require 'rails_helper'

RSpec.describe 'Guest Login', type: :system do
  # Cloudinaryの削除コールをモック
  before do
    allow(Cloudinary::Uploader).to receive(:destroy).and_return({ 'result' => 'ok' })

    # DBクリーンアップ
    Reaction.delete_all
    ReminderLog.delete_all
    WebPushSubscription.delete_all
    UserAchievement.delete_all
    Post.delete_all
    Walk.delete_all
    User.delete_all
  end

  context 'when admin user exists (data source)', js: true do
    let!(:admin_user) { FactoryBot.create(:user, :admin, goal_meters: 8000) }

    before do
      # 管理者データ作成（コピー元）
      FactoryBot.create(:walk, user: admin_user, walked_on: 1.day.ago, kilometers: 5)
    end

    it 'logs in as guest and deletes account on logout' do
      # 1. ログイン画面へアクセス
      visit new_user_session_path

      # 2. ゲストログイン実行
      # ゲストユーザーが1人増える
      expect do
        click_button 'ゲストで試してみる'
      end.to change(User, :count).by(1)
      # 3. ログイン成功を確認
      # ホーム画面（root_path）に遷移していることを確認
      expect(page).to have_current_path(root_path)
      # 認証が必要なコンテンツが表示されていることを確認
      expect(page).to have_content '今日の散歩'

      # 4. ゲストユーザーの特定
      guest = User.last
      expect(guest.role).to eq 'guest'
      expect(guest.walks.count).to eq 1 # データがコピーされていること

      # 5. ログアウト実行
      # ゲストユーザーが削除される
      expect do
        # ドロップダウンを開く
        find('button[data-action="click->dropdown#toggle"]').click
        click_link 'ログアウト'
      end.to change(User, :count).by(-1)
      expect(page).to have_content 'ログアウトしました。'
    end
  end

  context 'when no admin user exists (fallback)', js: true do
    it 'creates a fallback guest and logs in' do
      visit new_user_session_path
      click_button 'ゲストで試してみる'

      expect(page).to have_content 'ゲストモードとしてログインしました。'
      expect(User.last.role).to eq 'guest'
      expect(User.last.walks.count).to eq 0

      # Logout
      find('button[data-action="click->dropdown#toggle"]').click
      click_link 'ログアウト'
      expect(page).to have_content 'ログアウトしました。'
    end
  end
end
