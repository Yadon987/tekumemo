require "rails_helper"

RSpec.describe "ユーザー認証・認可", type: :system, js: true do
  describe "ログイン" do
    let!(:user) { User.create!(name: "テストユーザー", email: "test@example.com", password: "password123", target_distance: 5000) }

    it "正しいメールアドレスとパスワードでログインできること" do
      visit new_user_session_path
      fill_in "メールアドレス", with: "test@example.com"
      fill_in "login-password-field", with: "password123"
      within "#new_user" do
        click_button "ログイン"
      end

      expect(page).to have_content 'ログインしました。'
      expect(current_path).to eq root_path
    end

    it "誤ったパスワードではログインできないこと" do
      visit new_user_session_path
      fill_in "メールアドレス", with: "test@example.com"
      fill_in "login-password-field", with: "wrongpassword"
      within "#new_user" do
        click_button "ログイン"
      end

      expect(page).to have_content 'メールアドレスまたはパスワードが違います。'
      expect(current_path).to eq new_user_session_path
    end

    it "存在しないメールアドレスではログインできないこと" do
      visit new_user_session_path
      fill_in "メールアドレス", with: "unknown@example.com"
      fill_in "login-password-field", with: "password123"
      within "#new_user" do
        click_button "ログイン"
      end

      expect(page).to have_content 'メールアドレスまたはパスワードが違います。'
      expect(current_path).to eq new_user_session_path
    end
  end

  describe "ログアウト" do
    let!(:user) { User.create!(name: "テストユーザー", email: "test@example.com", password: "password123", target_distance: 5000) }

    before do
      login_as(user, scope: :user)
      visit root_path
    end

    it "ログアウトできること" do
      # アバター画像をクリックしてドロップダウンを開く
      # 画像がない場合（イニシャル表示）も考慮して、ボタン自体をクリックする
      find("button[data-dropdown-target='button']").click

      # ドロップダウンが表示されるのを待ってからログアウトをクリック
      # "ログアウト" のリンクが表示されるまで待機する
      expect(page).to have_content("ログアウト")
      click_link "ログアウト"

      expect(page).to have_content 'ログアウトしました。'
      expect(current_path).to eq new_user_session_path
    end
  end

  describe "アクセス制御" do
    let!(:user) { User.create!(name: "テストユーザー", email: "test@example.com", password: "password123", target_distance: 5000) }

    context "ログインしていない場合" do
      it "設定画面にアクセスするとログイン画面にリダイレクトされること" do
        visit edit_user_registration_path
        expect(page).to have_content 'アカウント登録もしくはログインしてください。'
        expect(current_path).to eq new_user_session_path
      end

      it "トップページにアクセスするとLPが表示されること" do
        visit root_path
        expect(page).to have_content 'てくメモ'
        expect(page).to have_link 'ログイン'
        expect(page).to have_link '新規登録してはじめる'
        expect(current_path).to eq root_path
      end
    end

    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "ログイン画面にアクセスするとトップページにリダイレクトされること" do
        visit new_user_session_path
        expect(page).to have_content 'すでにログインしています。'
        expect(current_path).to eq root_path
      end

      it "新規登録画面にアクセスするとトップページにリダイレクトされること" do
        visit new_user_registration_path
        expect(page).to have_content 'すでにログインしています。'
        expect(current_path).to eq root_path
      end
    end
  end

  describe "パスワードリセット" do
    it "パスワードリセット画面が表示されること" do
      visit new_user_session_path
      click_link "忘れた場合"

      # パスワードリセット画面のフォームがあるか確認
      expect(page).to have_selector("form[action*='password']")
      expect(page).to have_field("メールアドレス")
      # expect(page).to have_content("Soon")
      # expect(page).to have_content("現在開発中です")
    end
  end
end
