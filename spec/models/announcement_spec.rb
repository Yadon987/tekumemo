require 'rails_helper'

RSpec.describe Announcement, type: :model do
  describe 'コールバック' do
    before do
      Notification.delete_all
      Reaction.delete_all
      Post.delete_all
      Walk.delete_all
      Announcement.delete_all
      User.delete_all
    end

    let!(:user1) { FactoryBot.create(:user) }
    let!(:user2) { FactoryBot.create(:user) }

    context 'お知らせが公開された場合' do
      it '全ユーザーに通知が作成されること' do
        expect do
          FactoryBot.create(:announcement, is_published: true, published_at: Time.current)
        end.to change(Notification, :count).by(2)
      end
    end

    context 'お知らせが非公開で作成された場合' do
      it '通知は作成されないこと' do
        expect do
          FactoryBot.create(:announcement, is_published: false)
        end.not_to change(Notification, :count)
      end
    end

    context '非公開のお知らせが公開に更新された場合' do
      let(:announcement) { FactoryBot.create(:announcement, is_published: false) }

      it '全ユーザーに通知が作成されること' do
        expect do
          announcement.update!(is_published: true, published_at: Time.current)
        end.to change(Notification, :count).by(2)
      end
    end

    context '公開済みのお知らせが更新された場合' do
      let!(:announcement) { FactoryBot.create(:announcement, is_published: true, published_at: Time.current) }

      it '通知は再作成されないこと' do
        # 最初の作成で通知が作られているはず
        expect(Notification.count).to eq(2)

        expect do
          announcement.update!(title: '更新されたタイトル')
        end.not_to change(Notification, :count)
      end
    end
  end
end
