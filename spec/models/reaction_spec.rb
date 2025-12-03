require 'rails_helper'

RSpec.describe Reaction, type: :model do
  describe 'バリデーション' do
    let(:reaction) { build(:reaction) }

    context '正常系' do
      it 'すべての値が正しく設定されていれば有効であること' do
        expect(reaction).to be_valid
      end
    end

    context '異常系' do
      it 'ユーザー(user)がない場合は無効であること' do
        reaction.user = nil
        expect(reaction).to be_invalid
      end

      it '投稿(post)がない場合は無効であること' do
        reaction.post = nil
        expect(reaction).to be_invalid
      end

      it '種類(kind)がない場合は無効であること' do
        reaction.kind = nil
        expect(reaction).to be_invalid
      end

      it '同じユーザーが同じ投稿に同じ種類のリアクションを2回つけられないこと' do
        # ユーザーと投稿を作成
        user = create(:user)
        post = create(:post)
        kind = :thumbs_up

        # 1つ目のリアクションを作成
        create(:reaction, user: user, post: post, kind: kind)

        # 2つ目のリアクション（同じ条件）を作成しようとする
        duplicate_reaction = build(:reaction, user: user, post: post, kind: kind)

        expect(duplicate_reaction).to be_invalid
        expect(duplicate_reaction.errors[:user_id]).to include('は同じ投稿に同じリアクションを複数回つけられません')
      end

      it '同じユーザーでも違う種類のリアクションならつけられること' do
        user = create(:user)
        post = create(:post)

        # 1つ目のリアクション（ハート）
        create(:reaction, user: user, post: post, kind: :heart)

        # 2つ目のリアクション（いいね）
        second_reaction = build(:reaction, user: user, post: post, kind: :thumbs_up)

        expect(second_reaction).to be_valid
      end
    end
  end

  describe 'アソシエーション' do
    it 'Userに属していること' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end

    it 'Postに属していること' do
      association = described_class.reflect_on_association(:post)
      expect(association.macro).to eq :belongs_to
    end
  end
end
