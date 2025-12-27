require 'rails_helper'

RSpec.describe Achievement, type: :model do
  describe 'バリデーション' do
    it '名前、説明、条件、アイコンがあれば有効であること' do
      achievement = FactoryBot.build(:achievement)
      expect(achievement).to be_valid
    end

    it '名前がなければ無効であること' do
      achievement = FactoryBot.build(:achievement, name: nil)
      achievement.valid?
      expect(achievement.errors[:name]).to include("を入力してください")
    end

    it '条件値が0以下なら無効であること' do
      achievement = FactoryBot.build(:achievement, condition_value: 0)
      achievement.valid?
      expect(achievement.errors[:condition_value]).to include("は0より大きい値にしてください")
    end
  end

  describe 'Enum' do
    it 'condition_typeが正しく定義されていること' do
      expect(Achievement.condition_types.keys).to include('total_steps', 'total_distance', 'login_streak', 'post_count')
    end
  end
end
