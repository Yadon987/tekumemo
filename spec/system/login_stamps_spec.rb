require 'rails_helper'

RSpec.describe "LoginStamps", type: :system, js: true do
  # Chrome起動設定

  # テストデータの準備
  let(:user) { FactoryBot.create(:user, name: "スタンプ太郎") }

  before do
    # ログイン処理
    login_as(user, scope: :user)
    visit root_path
  end

  describe "カレンダー画面の表示" do
    before do
      visit login_stamps_path
    end

    it "現在の年月が表示されていること" do
      current_month = Date.current.strftime("%Y年%m月")
      expect(page).to have_content current_month
    end

    it "カレンダーの日付が表示されていること" do
      today_day = Date.current.day.to_s
      # 日付の数字が表示されているか確認（カレンダー内の日付セル）
      expect(page).to have_css(".date-number", text: today_day)
    end
  end

  describe "スタンプの表示" do
    context "散歩記録がある場合" do
      let!(:walk) { FactoryBot.create(:walk, user: user, walked_on: Date.current) }

      before do
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
        # 「てくてく日数」というテキストを含む要素を特定
        # デザイン変更に伴い、背景色クラスではなくテキストで親要素を探す
        target_card = find(:xpath, "//div[contains(., 'てくてく日数')][contains(@class, 'rounded-[2.5rem]')]")

        within target_card do
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
        FactoryBot.create(:walk, user: user, walked_on: Date.current)
        FactoryBot.create(:walk, user: user, walked_on: 1.day.ago.to_date)
        visit login_stamps_path
      end

      it "連続日数が「2日」と表示されること" do
        # 連続日数のカード内の数字を確認
        # デザイン変更に伴い、背景色クラスではなくテキストで親要素を探す
        target_card = find(:xpath, "//div[contains(., '連続')][contains(@class, 'rounded-[2.5rem]')]")

        within target_card do
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
      find("a", text: "chevron_left").click

      expect(page).to have_content prev_month
    end

    it "次月ボタンを押すと次月のカレンダーが表示されること" do
      next_month = 1.month.since.strftime("%Y年%m月")

      # 次月ボタン（chevron_right）をクリック
      find("a", text: "chevron_right").click

      # 画面遷移を待つ
      expect(page).to have_content next_month
    end
  end
end
