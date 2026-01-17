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
        walk = FactoryBot.build(:walk, user: user, steps: nil, calories: nil)
        expect(walk).to be_valid
      end
    end

    context '必須項目の検証' do
      it '日付(walked_on)がない場合は無効であること' do
        walk = FactoryBot.build(:walk, user: user, walked_on: nil)
        expect(walk).to be_invalid
        expect(walk.errors[:walked_on]).to include('を入力してください')
      end

      it '時間(minutes)がない場合は無効であること' do
        walk = FactoryBot.build(:walk, user: user, minutes: nil)
        expect(walk).to be_invalid
        expect(walk.errors[:minutes]).to include('を入力してください')
      end

      it '距離(kilometers)がない場合は無効であること' do
        walk = FactoryBot.build(:walk, user: user, kilometers: nil)
        expect(walk).to be_invalid
        expect(walk.errors[:kilometers]).to include('を入力してください')
      end
    end

    context '数値の検証' do
      it '時間(minutes)は0より大きい整数であること' do
        walk = FactoryBot.build(:walk, user: user, minutes: 0)
        expect(walk).to be_invalid

        walk.minutes = 1.5 # 整数のみ
        expect(walk).to be_invalid
      end

      it '距離(kilometers)は0より大きい数値であること' do
        walk = FactoryBot.build(:walk, user: user, kilometers: 0)
        expect(walk).to be_invalid

        walk.kilometers = 0.1 # 小数はOK
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
        expect(duplicate_walk.errors[:walked_on]).to include('の記録は既に存在します。同じ日付の記録を編集、もしくは削除してください。')
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

        expect(Walk.where(id: [walk1.id, walk2.id, walk3.id]).recent).to eq([walk2, walk3, walk1])
      end
    end
  end

  describe 'コールバック(daypart自動設定)' do
    it '作成時間に応じて適切な時間帯が設定されること' do
      # 04:00 - 08:59 -> early_morning
      walk = FactoryBot.create(:walk, created_at: Time.current.change(hour: 5))
      expect(walk.daypart).to eq 'early_morning'

      # 09:00 - 15:59 -> day
      walk = FactoryBot.create(:walk, created_at: Time.current.change(hour: 12))
      expect(walk.daypart).to eq 'day'

      # 16:00 - 18:59 -> evening
      walk = FactoryBot.create(:walk, created_at: Time.current.change(hour: 17))
      expect(walk.daypart).to eq 'evening'

      # 19:00 - 03:59 -> night
      walk = FactoryBot.create(:walk, created_at: Time.current.change(hour: 22))
      expect(walk.daypart).to eq 'night'
    end

    it '明示的に指定した場合はその値が優先されること' do
      walk = FactoryBot.create(:walk, daypart: :night, created_at: Time.current.change(hour: 12))
      expect(walk.daypart).to eq 'night'
    end
  end
end
