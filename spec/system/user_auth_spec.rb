require "rails_helper"

RSpec.describe "ユーザー認証・認可", type: :system do
  before do
    driven_by(:rack_test)
  end

  describe "ログイン" do
    let!(:user) { User.create!(name: "テストユーザー", email: "test@example.com", password: "password123", target_distance: 5000) }

    it "正しいメールアドレスとパスワードでログインできること" do
      visit new_user_session_path
      fill_in "メールアドレス", with: "test@example.com"
      fill_in "login-password-field", with: "password123"
      within "#new_user" do
        click_button "ログインする"
      end

      expect(page).to have_content 'ログインしました。'
      expect(current_path).to eq root_path
    end

    it "誤ったパスワードではログインできないこと" do
      visit new_user_session_path
      fill_in "メールアドレス", with: "test@example.com"
      fill_in "login-password-field", with: "wrongpassword"
      within "#new_user" do
        click_button "ログインする"
      end

      expect(page).to have_content 'メールアドレスまたはパスワードが違います。'
      expect(current_path).to eq new_user_session_path
    end

    it "存在しないメールアドレスではログインできないこと" do
      visit new_user_session_path
      fill_in "メールアドレス", with: "unknown@example.com"
      fill_in "login-password-field", with: "password123"
      within "#new_user" do
        click_button "ログインする"
      end

      expect(page).to have_content 'メールアドレスまたはパスワードが違います。'
      expect(current_path).to eq new_user_session_path
    end
  end

  describe "ログアウト" do
    let!(:user) { User.create!(name: "テストユーザー", email: "test@example.com", password: "password123", target_distance: 5000) }

    before do
      sign_in user
      visit root_path
    end

    it "ログアウトできること" do
      # ヘッダーのアバターをクリックしてドロップダウンを表示（JSが必要だがrack_testなので直接リンクを踏むか、ボタンを探す）
      # rack_testではhoverやclickによるJSイベントは発火しないが、
      # リンクが見えていればclick_linkで遷移できる。
      # ただし、ドロップダウン内にあるため、Capybaraが見つけられない可能性がある。
      # その場合は href を指定してリンクをクリックするか、直接DELETEリクエストを送る必要があるが、
      # System SpecではUI操作を模倣すべき。

      # ドロップダウンがhiddenでも、rack_testならDOM内にあればクリックできる場合がある。
      # もしダメなら、JSドライバを使う必要があるが、ここでは一旦試す。

      # ログアウトボタンは "ログアウト" というテキストを持っている
      # ただし、ドロップダウン内にある

      # Capybaraのrack_testドライバはvisible: falseの要素をクリックできないデフォルト設定があるかもしれない
      # ここではドロップダウンを開く操作（JS）ができないので、
      # ログアウトリンクを直接探してクリックする（visible: :all オプションが必要かも）

      # ログアウトリンクをクリック（非表示要素も対象にする）
      find("a", text: "ログアウト", visible: :all).click

      expect(page).to have_content 'ログアウトしました。'
      expect(current_path).to eq new_user_session_path
    end
  end

  describe "アクセス制御" do
    let!(:user) { User.create!(name: "テストユーザー", email: "test@example.com", password: "password123", target_distance: 5000) }

    context "ログインしていない場合" do
      it "設定画面にアクセスするとログイン画面にリダイレクトされること" do
        visit edit_user_registration_path
        expect(current_path).to eq new_user_session_path
        expect(page).to have_content 'アカウント登録もしくはログインしてください。'
      end

      it "トップページにアクセスするとログイン画面にリダイレクトされること" do
        visit root_path
        expect(current_path).to eq new_user_session_path
        expect(page).to have_content 'アカウント登録もしくはログインしてください。'
      end
    end

    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "ログイン画面にアクセスするとトップページにリダイレクトされること" do
        visit new_user_session_path
        expect(current_path).to eq root_path
        expect(page).to have_content 'すでにログインしています。'
      end

      it "新規登録画面にアクセスするとトップページにリダイレクトされること" do
        visit new_user_registration_path
        expect(current_path).to eq root_path
        expect(page).to have_content 'すでにログインしています。'
      end
    end
  end

  describe "パスワードリセット" do
    it "パスワードリセット画面が表示されること" do
      visit new_user_session_path
      click_link "パスワードをお忘れですか?"

      expect(page).to have_content("Coming")
      expect(page).to have_content("Soon")
      expect(page).to have_content("現在開発中です")
    end
  end
end
