require 'rails_helper'

RSpec.describe "Walks", type: :system do
  before do
    driven_by(:rack_test)
    Capybara.app_host = "http://localhost"
  end

  describe "散歩記録の新規作成" do
    let(:user) { User.create!(email: "test@example.com", password: "password") }

    before do
      # ログイン処理
      visit new_user_session_path
      fill_in "user_email", with: user.email
      fill_in "login-password-field", with: user.password
      click_button "ログインする"
    end

    context "フォームに正常な値を入力した場合" do
      it "散歩記録が保存され、一覧画面に表示されること" do
        # 新規作成画面へ移動
        visit new_walk_path

        # フォームの入力
        # 日付はデフォルトで今日が入っているはずだが、念のため確認
        expect(page).to have_field "散歩日"

        fill_in "場所", with: "テスト公園"
        fill_in "距離（km）（任意）", with: "5.5"
        fill_in "時間（分）（任意）", with: "60"
        fill_in "歩数（任意）", with: "8000"
        fill_in "消費カロリー（kcal）（任意）", with: "300"
        fill_in "メモ（任意）", with: "テスト散歩の記録です"

        # 保存ボタンをクリック
        click_button "散歩記録を保存"

        # 保存後の検証
        # 一覧画面にリダイレクトされているか確認
        expect(current_path).to eq walks_path
        expect(page).to have_content "散歩記録を作成しました"

        # 保存されたデータが表示されているか確認
        expect(page).to have_content "テスト公園"
        expect(page).to have_content "5.5 km"
        expect(page).to have_content "60 分"
        expect(page).to have_content "8,000 歩"
        expect(page).to have_content "300 kcal"
        expect(page).to have_content "テスト散歩の記録です"
      end
    end
  end
end
