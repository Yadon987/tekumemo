require 'rails_helper'

RSpec.describe "Admin::Users", type: :system do
  let!(:admin_user) { create(:user, :admin) }
  let!(:general_user) { create(:user, :general) }

  describe "管理者権限の制御" do
    context "一般ユーザーとしてログインしている場合" do
      before do
        sign_in general_user
      end

      it "管理画面にアクセスできず、トップページにリダイレクトされる" do
        visit admin_users_path
        expect(current_path).to eq root_path
        expect(page).to have_content "管理者権限が必要です"
      end
    end

    context "管理者としてログインしている場合" do
      before do
        sign_in admin_user
      end

      it "管理画面（ユーザー一覧）にアクセスできる" do
        visit admin_users_path
        expect(current_path).to eq admin_users_path
        expect(page).to have_content "ユーザー管理"
        expect(page).to have_content general_user.name
      end
    end
  end

  describe "ユーザー削除機能" do
    before do
      sign_in admin_user
      visit admin_users_path
    end


    # 注意: このテストは非常に重く、Docker環境では150秒以上かかることがあります
    # リソース不足の環境ではタイムアウトする可能性があるため、一時的にpending
    # TODO: CI環境またはリソースに余裕のある環境でのみ実行するように修正する
    it "一般ユーザーを削除できる", js: true do
      # ページにユーザーが表示されていることを確認（メールアドレスで特定）
      expect(page).to have_content general_user.email

      # ページの読み込みを確実に待つ（メールアドレスで特定）
      expect(page).to have_selector('tr', text: general_user.email, wait: 10)

      # 削除対象のユーザーの行を見つける（メールアドレスで特定して曖昧さを回避）
      user_row = find('tr', text: general_user.email)

      # 削除ボタンをクリックして確認ダイアログを承認
      within(user_row) do
        page.accept_confirm do
          click_button "削除"
        end
      end

      # 削除成功メッセージの表示を待つ
      expect(page).to have_content "ユーザー「#{general_user.name}」を削除しました", wait: 10
      expect(page).not_to have_content general_user.email
    end
  end
end
