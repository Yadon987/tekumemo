require "rails_helper"

RSpec.describe "ユーザー設定", type: :system do
  before do
    driven_by(:rack_test)
  end

  # js: true の場合のみChromeを使用
  before(:each, js: true) do
    driven_by(:selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]) do |driver_option|
      driver_option.add_argument('--no-sandbox')
      driver_option.add_argument('--disable-dev-shm-usage')
      driver_option.add_argument('--headless=new')
      driver_option.add_argument('--disable-gpu')
    end
  end

  before do
    # OmniAuthのモック設定
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  describe "新規登録とログイン" do
    it "メールアドレスで新規登録し、ログインできること" do
      visit new_user_registration_path

      fill_in "ユーザー名（表示名）", with: "テストユーザー"
      fill_in "メールアドレス", with: "new@example.com"
      fill_in "パスワード", with: "password123"
      fill_in "register-password-confirmation-field", with: "password123"
      puts page.html # デバッグ用
      click_button "登録する"

      expect(page).to have_content("アカウント登録が完了しました。")
      expect(page).to have_content("テストユーザー")
    end

    context "入力内容に不備がある場合" do
      it "必須項目が未入力だと登録できず、エラーメッセージが表示されること" do
        visit new_user_registration_path
        # フォーム内の登録ボタンをクリック
        within "#new_user" do
          click_button "登録する"
        end

        # エラーメッセージの検証
        expect(page).to have_content("エラー")
        expect(page).to have_content("メールアドレスを入力してください")
        expect(page).to have_content("パスワードを入力してください")
        expect(page).to have_content("ユーザー名を入力してください")
      end

      it "パスワード（確認用）が一致しないと登録できないこと" do
        visit new_user_registration_path
        fill_in "ユーザー名（表示名）", with: "テストユーザー"
        fill_in "メールアドレス", with: "new@example.com"
        fill_in "パスワード", with: "password123"
        fill_in "register-password-confirmation-field", with: "mismatch"
        within "#new_user" do
          click_button "登録する"
        end

        expect(page).to have_content("パスワード（確認）とパスワードの入力が一致しません")
      end
    end

    it "未連携のGoogleアカウントではログインできないこと" do
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
        provider: "google_oauth2",
        uid: "unlinked_uid",
        info: { email: "unlinked@example.com" },
        credentials: { token: "token", expires_at: Time.now.to_i + 3600 }
      })

      visit new_user_session_path
      # Googleログインボタンをクリック
      find("form[action='/users/auth/google_oauth2'] button").click

      expect(page).to have_content("このGoogleアカウントは連携されていません")
    end
  end

  describe "設定画面の操作" do
    let(:user) { FactoryBot.create(:user, name: "既存ユーザー", email: "user@example.com", password: "password123", target_distance: 5000) }

    before do
      sign_in user
      visit edit_user_registration_path
    end

    context "プロフィール更新（異常系）" do
      it "名前を空にすると更新できないこと" do
        fill_in "ユーザー名（表示名）", with: ""
        click_button "変更を保存する"
        expect(page).to have_content("ユーザー名を入力してください")
      end

      it "目標距離に不正な値（0以下）を入力すると更新できないこと" do
        fill_in "目標距離 (m)", with: "0"
        click_button "変更を保存する"
        expect(page).to have_content("目標距離は0より大きい値にしてください")
      end

      it "目標距離に不正な値（上限超え）を入力すると更新できないこと" do
        fill_in "目標距離 (m)", with: "100001"
        click_button "変更を保存する"
        expect(page).to have_content("目標距離は100000以下の値にしてください")
      end
    end

    it "プロフィール（名前・目標距離）を更新できること" do
      fill_in "ユーザー名（表示名）", with: "更新後のユーザー"
      fill_in "目標距離 (m)", with: "8000"
      click_button "変更を保存する"

      expect(page).to have_content("アカウント情報を変更しました。")
      expect(user.reload.name).to eq("更新後のユーザー")
      expect(user.reload.target_distance).to eq(8000)
    end

    it "パスワードを変更できること（現在のパスワード必須）" do
      fill_in "新しいパスワード（変更する場合のみ）", with: "newpassword"
      fill_in "パスワード確認", with: "newpassword"
      fill_in "現在のパスワード", with: "password123"
      click_button "変更を保存する"

      expect(page).to have_content("アカウント情報を変更しました。")
      expect(user.reload.valid_password?("newpassword")).to be true
    end

    it "現在のパスワードが間違っていると更新できないこと" do
      fill_in "新しいパスワード（変更する場合のみ）", with: "newpassword"
      fill_in "パスワード確認", with: "newpassword"
      fill_in "現在のパスワード", with: "wrongpassword"
      click_button "変更を保存する"

      expect(page).to have_content("現在のパスワードは不正な値です")
    end

    it "確認用パスワードが一致しないと更新できないこと" do
      fill_in "新しいパスワード（変更する場合のみ）", with: "newpassword"
      fill_in "パスワード確認", with: "mismatch"
      fill_in "現在のパスワード", with: "password123"
      click_button "変更を保存する"

      expect(page).to have_content("パスワード（確認）とパスワードの入力が一致しません")
    end

    # JSが必要なため、このテストケースのみSeleniumを使用
    it "Google連携を行い、その後解除できること", js: true do
      # Google連携のモック
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
        provider: "google_oauth2",
        uid: "linked_uid",
        info: { email: "user@example.com", image: "http://example.com/avatar.jpg" },
        credentials: { token: "token", expires_at: Time.now.to_i + 3600 }
      })

      # 連携ボタンをクリック
      click_button "連携する"

      expect(page).to have_content("Googleアカウントと連携しました")
      expect(page).to have_content("連携済み")
      expect(user.reload.google_uid).to eq("linked_uid")

      # 連携解除ボタン（モーダルを開く）をクリック
      find("button span[title='連携を解除する']").click

      # モーダルが表示されるのを確認
      expect(page).to have_content("Google連携の解除")
      expect(page).to have_content("現在のパスワードを入力してください")

      # パスワードを入力して解除
      within "#disconnect_modal" do
        fill_in "現在のパスワード", with: "password123"
        click_button "解除する"
      end

      expect(page).to have_content("Google連携を解除しました")

      # "未連携" という文字は表示されない仕様なので、"連携する" ボタンがあることを確認
      expect(page).to have_content("連携する")
      expect(page).not_to have_content("連携済み")

      # DB上で連携情報が消えているか確認
      user.reload
      expect(user.google_uid).to be_nil
      expect(user.google_token).to be_nil
    end

    it "Google連携解除時にパスワードを間違えると解除できないこと", js: true do
      # 事前にGoogle連携状態にする
      user.update!(
        google_uid: "linked_uid",
        google_token: "token",
        google_expires_at: Time.now + 1.hour
      )
      visit edit_user_registration_path

      # 連携解除ボタン（モーダルを開く）をクリック
      find("button span[title='連携を解除する']").click

      # 間違ったパスワードを入力
      within "#disconnect_modal" do
        fill_in "現在のパスワード", with: "wrongpassword"
        click_button "解除する"
      end

      expect(page).to have_content("パスワードが正しくありません")

      # 連携が解除されていないことを確認
      expect(page).to have_content("連携済み")
      expect(user.reload.google_uid).to eq("linked_uid")
    end

    it "アカウントを削除できること" do
      expect {
        click_button "削除する"
      }.to change(User, :count).by(-1)

      expect(page).to have_content("アカウントを削除しました。")
    end
  end
end
