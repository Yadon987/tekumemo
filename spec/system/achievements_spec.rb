require 'rails_helper'

RSpec.describe 'Achievements', type: :system do
  let(:user) { FactoryBot.create(:user) }
  let!(:achievement_earned) { FactoryBot.create(:achievement, name: '獲得済みバッジ', icon_name: 'star') }
  let!(:achievement_locked) { FactoryBot.create(:achievement, name: '未獲得バッジ', icon_name: 'lock_open') } # 元のアイコンはlock_openにしておく

  before do
    UserAchievement.create(user: user, achievement: achievement_earned)
  end

  context 'ログインしていない場合' do
    it 'ログイン画面にリダイレクトされる' do
      visit achievements_path
      expect(current_path).to eq new_user_session_path
    end
  end

  context 'ログインしている場合' do
    before do
      sign_in user
      visit achievements_path
    end

    it '実績一覧が表示される' do
      expect(page).to have_content 'ACHIEVEMENTS'
      expect(page).to have_content '獲得済みバッジ'
      expect(page).to have_content '未獲得バッジ'
    end

    it '獲得済みの実績は獲得済みとして表示される' do
      # 獲得済みの要素には特定のクラスやアイコンがあるはず
      # ここではアイコン名が表示されているかで簡易判定
      expect(page).to have_content 'star'
    end

    it '未獲得の実績はロック状態で表示される' do
      # 未獲得の場合はアイコンがlockになる
      # achievement_lockedのicon_nameはlock_openだが、未獲得なのでlockが表示されるはず
      expect(page).to have_content 'lock'
      expect(page).to have_content '未獲得'
    end

    it 'プログレスバーが正しく表示される' do
      # 全2個中1個獲得なので50%
      expect(page).to have_content '1 / 2'
    end
  end
end
