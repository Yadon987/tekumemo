require 'rails_helper'

RSpec.describe Walk, type: :model do
  # テストデータのセットアップ
  let(:user) { FactoryBot.build_stubbed(:user) }

  describe 'バリデーション' do
    context '正常系' do
      it 'すべての値が正しく入力されていれば有効であること' do
        walk = FactoryBot.build(:walk, user: user)
        expect(walk).to be_valid
      end

      it '歩数とカロリーは空でも有効であること' do
        walk = FactoryBot.build(:walk, user: user, steps: nil, calories_burned: nil)
        expect(walk).to be_valid
      end
    end

    context '必須項目の検証' do
      it '日付(walked_on)がない場合は無効であること' do
        walk = FactoryBot.build(:walk, user: user, walked_on: nil)
        expect(walk).to be_invalid
        expect(walk.errors[:walked_on]).to include("を入力してください")
      end

      it '時間(duration)がない場合は無効であること' do
        walk = FactoryBot.build(:walk, user: user, duration: nil)
        expect(walk).to be_invalid
        expect(walk.errors[:duration]).to include("を入力してください")
      end

      it '距離(distance)がない場合は無効であること' do
        walk = FactoryBot.build(:walk, user: user, distance: nil)
        expect(walk).to be_invalid
        expect(walk.errors[:distance]).to include("を入力してください")
      end
    end

    context '数値の検証' do
      it '時間(duration)は0より大きい整数であること' do
        walk = FactoryBot.build(:walk, user: user, duration: 0)
        expect(walk).to be_invalid

        walk.duration = 1.5 # 整数のみ
        expect(walk).to be_invalid
      end

      it '距離(distance)は0より大きい数値であること' do
        walk = FactoryBot.build(:walk, user: user, distance: 0)
        expect(walk).to be_invalid

        walk.distance = 0.1 # 小数はOK
        expect(walk).to be_valid
      end

      it '歩数(steps)は0以上の整数であること' do
        walk = FactoryBot.build(:walk, user: user, steps: -1)
        expect(walk).to be_invalid

        walk.steps = 0
        expect(walk).to be_valid
      end
    end

    context '一意性の検証' do
      let(:user) { FactoryBot.create(:user) }

      it '同じユーザーが同じ日に重複して記録できないこと' do
        # 1つ目の記録を作成
        FactoryBot.create(:walk, user: user, walked_on: Date.current)

        # 同じ日付で2つ目の記録を作成しようとする
        duplicate_walk = FactoryBot.build(:walk, user: user, walked_on: Date.current)
        expect(duplicate_walk).to be_invalid
        expect(duplicate_walk.errors[:walked_on]).to include("の記録は既に存在します。同じ日付の記録を編集、もしくは削除してください。")
      end

      it '異なるユーザーであれば同じ日付でも記録できること' do
        other_user = FactoryBot.create(:user)
        FactoryBot.create(:walk, user: user, walked_on: Date.current)

        other_user_walk = FactoryBot.build(:walk, user: other_user, walked_on: Date.current)
        expect(other_user_walk).to be_valid
      end
    end
  end

  describe 'スコープ' do
    let(:user) { FactoryBot.create(:user) }

    describe '.recent' do
      it '新しい日付順に並び替えられること' do
        walk1 = FactoryBot.create(:walk, user: user, walked_on: 3.days.ago)
        walk2 = FactoryBot.create(:walk, user: user, walked_on: 1.day.ago)
        walk3 = FactoryBot.create(:walk, user: user, walked_on: 2.days.ago)

        expect(Walk.where(id: [ walk1.id, walk2.id, walk3.id ]).recent).to eq([ walk2, walk3, walk1 ])
      end
    end
  end
end
