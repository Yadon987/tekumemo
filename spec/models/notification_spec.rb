require 'rails_helper'

RSpec.describe Notification, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:announcement) { FactoryBot.create(:announcement) }
  let(:notification) { FactoryBot.create(:notification, user: user, announcement: announcement) }

  describe 'アソシエーション' do
    it 'Userに属していること' do
      expect(notification.user).to be_a(User)
    end

    it 'Announcementに属していること' do
      expect(notification.announcement).to be_a(Announcement)
    end
  end

  describe 'スコープ' do
    let!(:unread_notification) { FactoryBot.create(:notification, user: user, announcement: announcement, read_at: nil) }
    let!(:read_notification) { FactoryBot.create(:notification, user: user, announcement: announcement, read_at: 1.day.ago) }

    describe '.unread' do
      it '未読の通知のみを取得すること' do
        expect(Notification.unread).to include(unread_notification)
        expect(Notification.unread).not_to include(read_notification)
      end
    end

    describe '.read' do
      it '既読の通知のみを取得すること' do
        expect(Notification.read).to include(read_notification)
        expect(Notification.read).not_to include(unread_notification)
      end
    end
  end

  describe 'メソッド' do
    describe '#mark_as_read!' do
      it '通知を既読にすること' do
        notification = FactoryBot.create(:notification, read_at: nil)
        notification.mark_as_read!
        expect(notification.reload.read_at).not_to be_nil
      end

      it '既に既読の場合は更新日時を変更しないこと' do
        read_time = 1.day.ago
        notification = FactoryBot.create(:notification, read_at: read_time)
        notification.mark_as_read!
        expect(notification.reload.read_at.to_i).to eq read_time.to_i
      end
    end

    describe '#unread?' do
      it '未読の場合はtrueを返すこと' do
        notification = FactoryBot.build(:notification, read_at: nil)
        expect(notification.unread?).to be true
      end

      it '既読の場合はfalseを返すこと' do
        notification = FactoryBot.build(:notification, read_at: Time.current)
        expect(notification.unread?).to be false
      end
    end
  end
end
