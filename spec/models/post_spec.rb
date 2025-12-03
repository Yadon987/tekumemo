require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'バリデーション' do
    let(:post) { build(:post) }

    context '正常系' do
      it 'すべての値が正しく設定されていれば有効であること' do
        expect(post).to be_valid
      end
    end

    context '異常系' do
      it '本文、天気、気分、散歩記録のすべてがない場合は無効であること' do
        post.body = nil
        post.weather = nil
        post.feeling = nil
        post.walk = nil
        expect(post).to be_invalid
        expect(post.errors[:base]).to include('本文、天気、気分、散歩記録のいずれか1つは入力してください')
      end

      it '本文(body)が200文字を超える場合は無効であること' do
        post.body = 'a' * 201
        expect(post).to be_invalid
        expect(post.errors[:body]).to include('は200文字以内で入力してください')
      end
    end
  end

  describe 'アソシエーション' do
    it 'Userに属していること' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end

    it 'Reactionを複数持っていること' do
      association = described_class.reflect_on_association(:reactions)
      expect(association.macro).to eq :has_many
    end

    it '削除されたらReactionも削除されること' do
      post = create(:post)
      create(:reaction, post: post)
      expect { post.destroy }.to change(Reaction, :count).by(-1)
    end
  end
end
