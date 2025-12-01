require 'rails_helper'

RSpec.describe "WalksPagination", type: :system do
  # Chrome起動オプション（安定稼働用）
  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]) do |driver_option|
      driver_option.add_argument('--no-sandbox')
      driver_option.add_argument('--disable-dev-shm-usage')
      driver_option.add_argument('--headless=new')
      driver_option.add_argument('--disable-gpu')
      driver_option.add_argument('--disable-infobars')
      driver_option.add_argument('--disable-extensions')
    end
  end

  let(:user) { User.create!(email: "pagination_test@example.com", password: "password", name: "ページネーション太郎") }

  before do
    # 15件のデータを作成
    # 場所0: 今日, 場所1: 昨日 ... 場所14: 14日前
    15.times do |i|
      Walk.create!(
        user: user,
        walked_on: Date.today - i.days,
        location: "場所#{i}",
        distance: 1.0,
        duration: 10,
        steps: 1000,
        calories_burned: 50
      )
    end

    # ログイン処理
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "login-password-field", with: user.password
    click_button "ログインする"
    expect(page).to have_content "ログインしました"
  end

  it "ページネーションが表示され、ページ遷移ができること" do
    visit walks_path

    # 1ページ目の確認（日付が新しい順なので、場所0〜9が表示されるはず）
    expect(page).to have_content("場所0") # 今日の記録
    expect(page).to have_content("場所9") # 9日前の記録
    expect(page).not_to have_content("場所10") # 10日前の記録（2ページ目）

    # ページネーションの存在確認
    expect(page).to have_selector('nav[role="navigation"]')

    # 2ページ目へ移動（「次へ」ボタンをクリック）
    # アイコン化されていますが、rel="next" 属性で特定します
    find('a[rel="next"]').click

    # 2ページ目の確認
    expect(page).to have_content("場所10")
    expect(page).to have_content("場所14")
    expect(page).not_to have_content("場所0")
  end
end
