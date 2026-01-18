require 'rails_helper'

RSpec.describe ReminderLog, type: :model do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:announcement) { FactoryBot.build_stubbed(:announcement, is_published: false) }
  let(:reminder_log) { FactoryBot.build_stubbed(:reminder_log, user: user, announcement: announcement) }

  describe 'アソシエーション' do
    it 'Userに属していること' do
      expect(reminder_log.user).to be_a(User)
    end

    it 'Announcementに属していること' do
      expect(reminder_log.announcement).to be_a(Announcement)
    end
  end

  describe 'スコープ' do
    let(:user) { FactoryBot.create(:user) }
    let(:announcement1) { FactoryBot.create(:announcement, is_published: false) }
    let(:announcement2) { FactoryBot.create(:announcement, is_published: false) }
    let!(:unread_notification) do
      FactoryBot.create(:reminder_log, user: user, announcement: announcement1, read_at: nil)
    end
    let!(:read_notification) do
      FactoryBot.create(:reminder_log, user: user, announcement: announcement2, read_at: 1.day.ago)
    end

    describe '.unread' do
      it '未読の通知のみを取得すること' do
        expect(ReminderLog.unread).to include(unread_notification)
        expect(ReminderLog.unread).not_to include(read_notification)
      end
    end

    describe '.read' do
      it '既読の通知のみを取得すること' do
        expect(ReminderLog.read).to include(read_notification)
        expect(ReminderLog.read).not_to include(unread_notification)
      end
    end

    describe '.ordered_by_announcement' do
      let!(:old_announcement) { FactoryBot.create(:announcement, published_at: 2.days.ago, is_published: false) }
      let!(:new_announcement) { FactoryBot.create(:announcement, published_at: 1.day.ago, is_published: false) }
      # old_announcementの通知を「新しく」作成する（作成順と公開順を逆転させる）
      let!(:reminder_log_for_old) do
        FactoryBot.create(:reminder_log, user: user, announcement: old_announcement, created_at: Time.current)
      end
      let!(:reminder_log_for_new) do
        FactoryBot.create(:reminder_log, user: user, announcement: new_announcement, created_at: 1.hour.ago)
      end

      it 'お知らせの公開日順（降順）に並ぶこと' do
        # created_at順だと notification_for_old が先に来るはずだが、
        # ordered_by_announcement なら notification_for_new が先に来るはず
        target_ids = [reminder_log_for_old.id, reminder_log_for_new.id]
        reminder_logs = ReminderLog.where(id: target_ids).ordered_by_announcement
        expect(reminder_logs.first).to eq reminder_log_for_new
        expect(reminder_logs.last).to eq reminder_log_for_old
      end
    end
  end

  describe 'メソッド' do
    describe '#mark_as_read!' do
      it '通知を既読にすること' do
        reminder_log = FactoryBot.create(:reminder_log, read_at: nil)
        reminder_log.mark_as_read!
        expect(reminder_log.reload.read_at).not_to be_nil
      end

      it '既に既読の場合は更新日時を変更しないこと' do
        read_time = 1.day.ago
        reminder_log = FactoryBot.create(:reminder_log, read_at: read_time)
        reminder_log.mark_as_read!
        expect(reminder_log.reload.read_at.to_i).to eq read_time.to_i
      end
    end

    describe '#unread?' do
      it '未読の場合はtrueを返すこと' do
        reminder_log = FactoryBot.build(:reminder_log, read_at: nil)
        expect(reminder_log.unread?).to be true
      end

      it '既読の場合はfalseを返すこと' do
        reminder_log = FactoryBot.build(:reminder_log, read_at: Time.current)
        expect(reminder_log.unread?).to be false
      end
    end
  end
end
