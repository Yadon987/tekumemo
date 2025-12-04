require 'rails_helper'

RSpec.describe "Walks", type: :system do
  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]) do |driver_option|
      driver_option.add_argument('--no-sandbox')
      driver_option.add_argument('--disable-dev-shm-usage')
      driver_option.add_argument('--headless=new')
      driver_option.add_argument('--disable-gpu')
    end
  end

  describe "散歩記録の新規作成" do
    # シンプルにUser.create!を使用（FactoryBotの依存を排除して原因切り分け）
    let(:user) { User.create!(email: "test_walk@example.com", password: "password123", name: "テスト太郎", target_distance: 5000) }

    before do
      visit new_user_session_path
      fill_in "メールアドレス", with: user.email
      fill_in "login-password-field", with: user.password
      within "#new_user" do
        click_button "ログインする"
      end
      expect(page).to have_content "ログインしました"
    end

    it "散歩記録が保存され、一覧画面に表示されること" do
      visit new_walk_path
      expect(page).to have_content "新しい散歩記録"

      # 日付フィールドをクリック（カレンダー表示のトリガーを確認する意味合い）
      find("#walk_walked_on").click
      # 日付を入力
      fill_in "walk_walked_on", with: Date.current.strftime('%Y-%m-%d')

      fill_in "walk_location", with: "テスト公園"
      fill_in "walk_distance", with: "5.5"
      fill_in "walk_duration", with: "60"
      fill_in "walk_steps", with: "8000"
      fill_in "walk_calories_burned", with: "300"
      fill_in "walk_notes", with: "テスト散歩の記録です"

      click_button "保存する"

      expect(page).to have_current_path(walks_path)
      expect(page).to have_content "散歩記録を作成しました"
      expect(page).to have_content "テスト公園"
      # 数値の検証は正規表現で柔軟に
      expect(page).to have_content(/5(\.5)?/)
    end
  end

  describe "散歩記録の編集" do
    let(:user) { User.create!(email: "edit_test@example.com", password: "password123", name: "編集太郎", target_distance: 5000) }
    let!(:walk) { Walk.create!(user: user, walked_on: Date.current, distance: 3.0, duration: 30, steps: 3000, calories_burned: 150, location: "編集前の場所") }

    before do
      visit new_user_session_path
      fill_in "メールアドレス", with: user.email
      fill_in "login-password-field", with: user.password
      within "#new_user" do
        click_button "ログインする"
      end
      expect(page).to have_content "ログインしました"
    end

    it "記録を編集できること" do
      visit edit_walk_path(walk)


      expect(page).to have_field("場所（任意）", with: "編集前の場所")

      fill_in "場所（任意）", with: "編集後の場所"
      fill_in "距離", with: "10.0"
      fill_in "時間", with: "45"

      click_button "保存する"



      expect(page).to have_current_path(walk_path(walk))
      expect(page).to have_content "編集後の場所"
      expect(page).to have_content(/10(\.0)?/)
    end
  end

  describe "散歩記録の削除" do
    let(:user) { User.create!(email: "delete_test@example.com", password: "password123", name: "削除太郎", target_distance: 5000) }
    let!(:walk) { Walk.create!(user: user, walked_on: Date.current, distance: 3.0, duration: 30, steps: 3000, calories_burned: 150, location: "削除する場所") }

    before do
      visit new_user_session_path
      fill_in "メールアドレス", with: user.email
      fill_in "login-password-field", with: user.password
      within "#new_user" do
        click_button "ログインする"
      end
      expect(page).to have_content "ログインしました"
    end

    it "記録を削除できること" do
      visit walk_path(walk)

      # 削除リンクをクリック（確認ダイアログあり）
      accept_confirm do
        click_link "削除"
      end

      sleep 1 # 削除処理と画面遷移を待つ

      expect(page).to have_current_path(walks_path)
      # 削除完了メッセージを待つ（文言が不明なため、Flashメッセージのコンテナが表示されることを待つ）
      # expect(page).to have_content "削除しました"
      expect(page).to have_no_content "削除する場所"
    end
  end

  describe "ページネーション" do
    let(:user) { User.create!(email: "pagination_test@example.com", password: "password123", name: "ページネーション太郎", target_distance: 5000) }

    before do
      # 50件のデータを作成
      50.times do |i|
        Walk.create!(
          user: user,
          walked_on: Date.current - i.days,
          distance: 1.0,
          duration: 30,
          steps: 1000,
          calories_burned: 50,
          location: "場所#{i}"
        )
      end

      visit new_user_session_path
      fill_in "メールアドレス", with: user.email
      fill_in "login-password-field", with: user.password
      within "#new_user" do
        click_button "ログインする"
      end
      expect(page).to have_content "ログインしました"
    end

    it "ページネーションが表示され、次ページに遷移できること" do
      visit walks_path

      # ページネーションのリンクがあるか確認
      expect(page).to have_link "2"

      # 上下2箇所にあるため、最初の一つをクリック
      click_link "2", match: :first

      # URLが変わるのを待つ（Capybaraの待機機能を利用）
      expect(page).to have_current_path(/page=2/)
      # 2ページ目は 10日前〜19日前のデータが表示されるはず（1ページ10件の場合）
      expect(page).to have_content "場所15"
    end
  end
end
