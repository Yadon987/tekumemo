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

    it "一般ユーザーを削除できる", js: true do
      expect(page).to have_content general_user.name

      # 削除ボタンをクリック（確認ダイアログはTurboで処理されるため、accept_confirm等は不要な場合が多いが、ドライバによる）
      # Cuprite/Ferrumの場合はダイアログの自動承認設定が必要かもしれないが、
      # ここでは単純にボタンクリックを試みる

      # 注: 自分のアカウントには削除ボタンが表示されない仕様
      # TurboのconfirmダイアログはCupriteでは自動的にOKされる場合があるが、
      # accept_confirmブロックで囲むのが確実。ただし、タイミングによっては失敗することも。
      # ここではシンプルにクリックし、ダイアログが出ることを期待する。

      within all('tr').find { |row| row.text.include?(general_user.name) } do
        page.accept_confirm do
          click_button "削除"
        end
      end

      expect(page).to have_content "ユーザー「#{general_user.name}」を削除しました"
      expect(page).not_to have_content general_user.email
    end
  end
end
