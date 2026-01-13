require 'rails_helper'

RSpec.describe 'Guest Google Fit Simulation', type: :system do
  before do
    allow(Cloudinary::Uploader).to receive(:destroy).and_return({ 'result' => 'ok' })
    Reaction.delete_all
    Notification.delete_all
    UserAchievement.delete_all
    Post.delete_all
    Walk.delete_all
    User.delete_all
  end

  context 'as a guest user', js: true do
    it 'simulates Google Fit connection and data' do
      # ゲストログイン
      visit new_user_session_path
      click_button 'ゲストで試してみる'
      expect(page).to have_content 'ゲストモードとしてログインしました。'

      # 設定画面などで連携状態が「連携済み」になっているか確認したいが
      # UI上の場所が不明確なので、まずはAPI/Controllerの挙動を直接検証する方が確実だが
      # System SpecなのでUIを通したい。

      # Google Fitデータ取得APIを叩いてみる (JSfetch等で呼ばれる想定だが直接アクセス)
      # または、Walks/Stats画面でグラフが表示されるか...

      # ひとまず、ルートパス（ダッシュボード）にはGoogle Fitデータは出ない？
      # Stats画面があればそこへ。

      # Userモデルの挙動確認 (System Spec内でモデルを直接触るのはグレーだが確認のため)
      guest = User.order(:created_at).last
      expect(guest.role).to eq 'guest'
      expect(guest.google_token_valid?).to be true

      # GoogleFitServiceの挙動確認
      service = GoogleFitService.new(guest)
      data = service.fetch_activities(Date.today, Date.today)
      expect(data).not_to be_empty
      expect(data[:data][Date.today][:steps]).to be > 0
    end

    it 'api endpoint returns dummy data' do
      # ゲストログイン
      visit new_user_session_path
      click_button 'ゲストで試してみる'

      # APIエンドポイントへのアクセス（System Specではpage.driver.getなどでリクエストを送れる場合もあるが）
      # ここでは visit で JSON が返るか確認（ブラウザで表示）
      visit google_fit_daily_data_path(date: Date.today)

      # JSONレスポンスの検証
      # "steps": ... が含まれているはず
      expect(page.body).to include('steps')
      expect(page.body).to include('distance')
    end
  end
end
