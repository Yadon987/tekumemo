require 'rails_helper'

RSpec.describe UserAchievement, type: :model do
  describe 'バリデーション' do
    let(:user) { FactoryBot.create(:user) }
    let(:achievement) { FactoryBot.create(:achievement) }

    it 'ユーザーと実績の組み合わせがユニークであること' do
      UserAchievement.create(user: user, achievement: achievement)
      duplicate = UserAchievement.new(user: user, achievement: achievement)
      duplicate.valid?
      expect(duplicate.errors[:user_id]).to include('はすでに存在します')
    end
  end
end
