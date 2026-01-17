require 'rails_helper'

RSpec.describe 'Home', type: :system, js: true do
  # Chrome起動設定

  let(:user) { FactoryBot.create(:user, name: 'ホーム太郎') }

  before do
    # ログイン処理
    # ログイン処理をWardenヘルパーで実行（UI操作をスキップして安定化）
    login_as(user, scope: :user)
  end

  describe 'ホーム画面の表示' do
    before do
      # 外部サービスのモック化
      # 実際のリクエストを飛ばさないようにする

      # 位置情報のモック
      allow(GeolocationService).to receive(:get_location).and_return({
                                                                       latitude: 35.6895,
                                                                       longitude: 139.6917,
                                                                       city: 'Shinjuku',
                                                                       region: 'Tokyo'
                                                                     })

      # 天気情報のモック
      # ビューでは @weather[:today][:icon] のようにアクセスしているため構造を合わせる
      allow(WeatherService).to receive(:get_forecast).and_return({
                                                                   today: {
                                                                     temp: 20,
                                                                     condition: '晴れ',
                                                                     icon: 'sunny', # material symbolsの名前
                                                                     description: '快晴です'
                                                                   },
                                                                   tomorrow: {
                                                                     temp: 18,
                                                                     condition: '曇り',
                                                                     icon: 'cloud',
                                                                     description: '曇りです'
                                                                   }
                                                                 })

      visit root_path
    end

    it '位置情報と天気が表示されること' do
      # 非同期読み込み完了を待つ（特定の要素が表示されるまで待機）
      # 天気アイコンが表示されるまで待つことで、他の情報も読み込まれていることを保証する
      expect(page).to have_selector('.material-symbols-outlined', text: 'sunny')

      # 位置情報（Shinjuku または Tokyo）が表示されているか
      expect(page).to have_content 'Shinjuku'

      # 気温が表示されているか
      expect(page).to have_content '20'
    end

    context '今日の散歩記録がある場合' do
      before do
        FactoryBot.create(:walk,
                          user: user,
                          walked_on: Date.current,
                          kilometers: 5.5,
                          steps: 8000)
        visit root_path # リロードして反映
      end

      it '今日の記録が表示されること' do
        expect(page).to have_content '今日の散歩'

        # JavaScriptのカウンターで数値が表示されるため、data属性で値を確認する
        # 5.5km -> 5500m
        expect(page).to have_selector("[data-counter-target-value='5500']")

        # 歩数はそのまま表示される
        expect(page).to have_content '8,000'
      end
    end

    context '今日の散歩記録がない場合' do
      it '今日の散歩カードが表示され、距離が0mであること' do
        # 今日の散歩カード自体は常に表示される仕様
        expect(page).to have_content '今日の散歩'

        # 距離が0mであることを確認（data-counter-target-value="0"）
        # カウンターアニメーションのため、テキストは "0"
        within find('.bg-gradient-to-br.from-sky-400', text: '今日の散歩') do
          expect(page).to have_selector("[data-counter-target-value='0']")
          expect(page).to have_content 'm'
        end
      end
    end
  end
end
