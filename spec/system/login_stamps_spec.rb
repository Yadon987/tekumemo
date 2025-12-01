require 'rails_helper'

RSpec.describe "LoginStamps", type: :system do
  # Chrome起動設定
  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]) do |driver_option|
      driver_option.add_argument('--no-sandbox')
      driver_option.add_argument('--disable-dev-shm-usage')
      driver_option.add_argument('--headless=new')
      driver_option.add_argument('--disable-gpu')
    end
  end

  # テストデータの準備
  let(:user) { FactoryBot.create(:user, name: "スタンプ太郎") }

  before do
    # ログイン処理
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "login-password-field", with: user.password
    click_button "ログインする"
    expect(page).to have_content "ログインしました"
  end

  describe "カレンダー画面の表示" do
    before do
      visit login_stamps_path
    end

    it "現在の年月が表示されていること" do
      current_month = Date.today.strftime("%Y年%m月")
      expect(page).to have_content current_month
    end

    it "カレンダーの日付が表示されていること" do
      today_day = Date.today.day.to_s
      # 日付の数字が表示されているか確認（カレンダー内の日付セル）
      expect(page).to have_css(".date-number", text: today_day)
    end
  end

  describe "スタンプの表示" do
    context "散歩記録がある場合" do
      before do
        # 今日の散歩記録を作成
        FactoryBot.create(:walk, user: user, walked_on: Date.today)
        visit login_stamps_path
      end

      it "その日にスタンプが表示されること" do
        # スタンプアイコン（pets）が表示されているか
        expect(page).to have_content "pets"
        # has-stampクラスが付与されているか
        expect(page).to have_css(".calendar-day.has-stamp")
      end

      it "「てくてく日数」が1日と表示されること" do
        # 今月の散歩日数の表示確認
        within first(".bg-gradient-to-br.from-cyan-400") do
          expect(page).to have_content "1"
        end
      end
    end

    context "散歩記録がない場合" do
      before do
        visit login_stamps_path
      end

      it "スタンプが表示されないこと" do
        expect(page).not_to have_css(".calendar-day.has-stamp")
      end

      it "今日の日付には「今日」と表示されること" do
        # 今日のセル内に「今日」という文字があるか
        today_cell = find(".calendar-day.today")
        expect(today_cell).to have_content "今日"
      end
    end
  end

  describe "連続日数の表示" do
    context "昨日と今日連続で散歩している場合" do
      before do
        FactoryBot.create(:walk, user: user, walked_on: Date.today)
        FactoryBot.create(:walk, user: user, walked_on: 1.day.ago.to_date)
        visit login_stamps_path
      end

      it "連続日数が「2日」と表示されること" do
        # 連続日数のカード内の数字を確認
        # カードの特徴的なクラスで特定
        within first(".bg-gradient-to-br.from-orange-400") do
          expect(page).to have_content "2"
        end
      end
    end
  end

  describe "月移動の動作" do
    before do
      visit login_stamps_path
    end

    it "前月ボタンを押すと前月のカレンダーが表示されること" do
      prev_month = 1.month.ago.strftime("%Y年%m月")

      # 前月ボタン（chevron_left）をクリック
      find("a[href*='start_date'] .material-symbols-outlined", text: "chevron_left").click

      expect(page).to have_content prev_month
    end

    it "次月ボタンを押すと次月のカレンダーが表示されること" do
      next_month = 1.month.since.strftime("%Y年%m月")

      # 次月ボタン（chevron_right）をクリック
      find("a[href*='start_date'] .material-symbols-outlined", text: "chevron_right").click

      expect(page).to have_content next_month
    end
  end
end
