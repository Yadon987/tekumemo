require 'rails_helper'

RSpec.describe 'Rankings', type: :system, js: true do
  let(:user) { FactoryBot.create(:user, name: '自分', email: 'me@example.com') }
  let!(:other_user) { FactoryBot.create(:user, name: 'ライバル', email: 'rival@example.com') }

  describe '同率順位の表示' do
    let!(:rival2) { FactoryBot.create(:user, email: 'rival2@example.com', name: 'ライバル2') }

    before do
      # ユーザーとライバル1、ライバル2が全員同じ距離（10km）を歩いたとする
      # User.rankingの仕様上、同距離の場合はID順などで順位が決まるが、
      # ここでは全員が表示され、距離が正しいことを確認する
      create(:walk, user: user, walked_on: Date.current, distance: 10.0, duration: 60)
      create(:walk, user: other_user, walked_on: Date.current, distance: 10.0, duration: 60)
      create(:walk, user: rival2, walked_on: Date.current, distance: 10.0, duration: 60)

      # キャッシュクリア
      Rails.cache.clear

      login_as(user, scope: :user)
      visit rankings_path
    end

    it '全員が表示され、距離が正しいこと' do
      # 全員10kmなので、表示されていることを確認
      expect(page).to have_content '10.0km', count: 3
      expect(page).to have_content '自分'
      expect(page).to have_content 'ライバル'
      expect(page).to have_content 'ライバル2'
    end
  end
end
