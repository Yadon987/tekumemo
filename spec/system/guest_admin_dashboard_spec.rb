require 'rails_helper'

RSpec.describe 'Guest Admin Dashboard', type: :system do
  before do
    allow(Cloudinary::Uploader).to receive(:destroy).and_return({ "result" => "ok" })
    Reaction.delete_all
    Notification.delete_all
    UserAchievement.delete_all
    Post.delete_all
    Walk.delete_all
    User.delete_all
  end

  context 'as a guest user', js: true do
    it 'can access dashboard but sees restricted view' do
      # Fallback guest login (simplest)
      visit new_user_session_path
      click_button 'ゲストログイン'

      expect(page).to have_content 'ゲストモードとしてログインしました。'

      # Visit Admin Dashboard
      visit admin_root_path

      # Should be allowed (no redirect to root)
      expect(page).to have_current_path(admin_root_path)
      expect(page).to have_content '管理者ダッシュボード'

      # Check for Overlay
      expect(page).to have_content 'ゲスト閲覧モード（保護中）'

      # Check for Dummy Data
      expect(page).to have_content 'ダミーユーザー1'
      expect(page).to have_content 'これはダミーの投稿です'

      # Check Global Stats (Real but mocked/empty)
      # Since no real posts, total posts should be 0 (or whatever logic)
      # Actually controller logic sets @total_posts = 9876 for guest!
      expect(page).to have_content '9876'
    end

    it 'cannot access other admin pages' do
      visit new_user_session_path
      click_button 'ゲストログイン'

      visit admin_users_path

      # Should redirect to root with alert
      expect(page).to have_current_path(root_path)
      expect(page).to have_content '管理者権限が必要です。'
    end
  end
end
