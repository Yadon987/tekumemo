require 'rails_helper'

RSpec.describe UsersHelper, type: :helper do
  describe '#user_avatar' do
    let(:user) { create(:user, name: 'Test User') }

    context 'Googleアバターを使用する場合' do
      before do
        user.update(avatar_url: 'http://example.com/avatar.jpg', avatar_type: :google)
      end

      it '画像タグが表示されること' do
        result = helper.user_avatar(user)
        expect(result).to have_selector("img[src='http://example.com/avatar.jpg']")
      end
    end

    context 'Googleアバターを使用しない場合' do
      before do
        user.update(avatar_type: :default)
      end

      it 'イニシャルが表示されること' do
        result = helper.user_avatar(user)
        expect(result).to have_content('TES') # Test User -> TES
        expect(result).to have_selector('div.bg-gradient-to-br')
      end

      it '名前が短い場合はそのまま表示されること' do
        user.update(name: 'AB')
        result = helper.user_avatar(user)
        expect(result).to have_content('AB')
      end

      it '名前がない場合はゲストと表示されること' do
        user.name = nil
        result = helper.user_avatar(user)
        expect(result).to have_content('ゲスト')
      end
    end
  end
end
