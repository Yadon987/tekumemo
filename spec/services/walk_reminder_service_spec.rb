require 'rails_helper'

RSpec.describe WalkReminderService, type: :service do
  describe '.send_reminders' do
    let(:reminder_time) { Time.zone.parse('2025-01-01 10:00:00') }

    before do
      allow(WebPushService).to receive(:send_notification)
      travel_to reminder_time
    end

    context '設定時刻になり、まだ散歩していない場合' do
      let!(:user) { create(:user, is_walk_reminder: true, walk_reminder_time: reminder_time) }

      it 'リマインダーを送信すること' do
        described_class.send_reminders

        expect(WebPushService).to have_received(:send_notification).with(
          user,
          title: '散歩の時間です！',
          body: anything,
          url: '/walks/new'
        )
      end
    end

    context '設定時刻だが、既に散歩済みの場合' do
      let!(:user) { create(:user, is_walk_reminder: true, walk_reminder_time: reminder_time) }

      before do
        create(:walk, user: user, walked_on: Date.current)
      end

      it 'リマインダーを送信しないこと' do
        described_class.send_reminders
        expect(WebPushService).not_to have_received(:send_notification)
      end
    end

    context '設定時刻ではない場合' do
      let!(:user) { create(:user, is_walk_reminder: true, walk_reminder_time: reminder_time) }

      it 'リマインダーを送信しないこと' do
        # 1時間ずらす
        travel_to(reminder_time + 1.hour) do
          described_class.send_reminders
        end

        expect(WebPushService).not_to have_received(:send_notification)
      end
    end

    context 'リマインダー設定が無効な場合' do
      let!(:user) { create(:user, is_walk_reminder: false, walk_reminder_time: reminder_time) }

      it 'リマインダーを送信しないこと' do
        described_class.send_reminders
        expect(WebPushService).not_to have_received(:send_notification)
      end
    end
  end
end
