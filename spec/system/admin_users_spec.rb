require 'rails_helper'

RSpec.describe 'Admin::Users', type: :system do
  let!(:admin_user) { create(:user, :admin) }
  let!(:general_user) { create(:user, :general) }

  describe '管理者権限の制御' do
    context '一般ユーザーとしてログインしている場合' do
      before do
        sign_in general_user
      end

      it '管理画面にアクセスできず、トップページにリダイレクトされる' do
        visit admin_users_path
        expect(current_path).to eq root_path
        expect(page).to have_content '管理者権限が必要です'
      end
    end

    context '管理者としてログインしている場合' do
      before do
        sign_in admin_user
      end

      it '管理画面（ユーザー一覧）にアクセスできる' do
        visit admin_users_path
        expect(current_path).to eq admin_users_path
        expect(page).to have_content 'ユーザー管理'
        expect(page).to have_content general_user.name
      end
    end
  end

  describe 'ユーザー削除機能' do
    before do
      sign_in admin_user
      visit admin_users_path
    end

    it '一般ユーザーを削除できる', js: true do
      # テスト実行前に不要なデータを削除して軽量化（全体実行時の遅延対策）
      Walk.where(user: general_user).delete_all
      Post.where(user: general_user).delete_all

      # 画面サイズリサイズを削除（負荷軽減）
      # page.current_window.resize_to(1400, 900)

      # 削除対象のユーザー行を特定
      user_row = find('tr', text: general_user.email)

      # 要素までスクロールして確実に表示させる
      user_row.scroll_to(:center)

      within(user_row) do
        # 削除リンクを特定（button_to から link_to に変更したため a タグ）
        delete_link = find('a', text: '削除')

        # 削除リンクがクリック可能になるまで待機
        expect(delete_link).to be_visible
        sleep 0.5 # 描画安定待ち

        # ダイアログを受け入れてクリック
        accept_confirm do
          delete_link.click
        end
      end

      # 削除成功を確認
      expect(page).to have_content "ユーザー「#{general_user.name}」を削除しました"
      expect(page).not_to have_content general_user.email
    end
  end
end
