require 'rails_helper'

RSpec.describe "Home", type: :system do
  # Chrome起動設定
  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]) do |driver_option|
      driver_option.add_argument('--no-sandbox')
      driver_option.add_argument('--disable-dev-shm-usage')
      driver_option.add_argument('--headless=new')
      driver_option.add_argument('--disable-gpu')
    end
  end

  let(:user) { FactoryBot.create(:user, name: "ホーム太郎") }

  before do
    # ログイン処理
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "login-password-field", with: user.password
    click_button "ログインする"
    expect(page).to have_content "ログインしました"
  end

  describe "ホーム画面の表示" do
    before do
      # 外部サービスのモック化
      # 実際のリクエストを飛ばさないようにする

      # 位置情報のモック
      allow(GeolocationService).to receive(:get_location).and_return({
        latitude: 35.6895,
        longitude: 139.6917,
        city: "Shinjuku",
        region: "Tokyo"
      })

      # 天気情報のモック
      # ビューでは @weather[:today][:icon] のようにアクセスしているため構造を合わせる
      allow(WeatherService).to receive(:get_forecast).and_return({
        today: {
          temp: 20,
          condition: "晴れ",
          icon: "sunny", # material symbolsの名前
          description: "快晴です"
        },
        tomorrow: {
          temp: 18,
          condition: "曇り",
          icon: "cloud",
          description: "曇りです"
        }
      })

      visit root_path
    end

    it "位置情報と天気が表示されること" do
      # 位置情報（Shinjuku または Tokyo）が表示されているか
      expect(page).to have_content "Shinjuku"

      # 気温が表示されているか
      expect(page).to have_content "20"

      # 天気アイコンが表示されているか（Material Symbolsのテキストとして）
      expect(page).to have_content "sunny"
    end

    context "今日の散歩記録がある場合" do
      before do
        FactoryBot.create(:walk,
          user: user,
          walked_on: Date.today,
          distance: 5.5,
          steps: 8000
        )
        visit root_path # リロードして反映
      end

      it "今日の記録が表示されること" do
        expect(page).to have_content "今日の散歩"

        # JavaScriptのカウンターで数値が表示されるため、data属性で値を確認する
        # 5.5km -> 5500m
        expect(page).to have_selector("[data-counter-target-value='5500']")

        # 歩数はそのまま表示される
        expect(page).to have_content "8,000"
      end
    end

    context "今日の散歩記録がない場合" do
      it "今日の散歩カードが表示され、距離が0mであること" do
        # 今日の散歩カード自体は常に表示される仕様
        expect(page).to have_content "今日の散歩"

        # 距離が0mであることを確認（data-counter-target-value="0"）
        # カウンターアニメーションのため、テキストは "0"
        within first(".bg-gradient-to-br.from-cyan-400") do
          expect(page).to have_content "0"
          expect(page).to have_content "m"
        end
      end
    end
  end
end
