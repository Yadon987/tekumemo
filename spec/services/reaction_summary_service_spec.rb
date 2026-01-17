require 'rails_helper'

RSpec.describe ReactionSummaryService, type: :service do
  describe '.send_summaries' do
    let(:user) { create(:user, is_reaction_summary: true) }
    let(:post) { create(:post, user: user) }
    let(:other_user) { create(:user) }

    before do
      # WebPushServiceのモック化
      allow(WebPushService).to receive(:send_notification)
    end

    context 'リアクションがある場合' do
      before do
        # 今日のリアクションを作成
        create(:reaction, post: post, user: other_user, stamp: 'thumbs_up', created_at: Time.current)
        create(:reaction, post: post, user: other_user, stamp: 'heart', created_at: Time.current)
        create(:reaction, post: post, user: other_user, stamp: 'sparkles', created_at: Time.current)
      end

      it '通知設定が有効なユーザーに通知を送信すること' do
        described_class.send_summaries

        expect(WebPushService).to have_received(:send_notification).with(
          user,
          title: 'リアクションまとめ',
          body: include('3件のリアクションがありました'),
          url: '/posts'
        )
      end

      it '通知ボックスに通知を作成すること' do
        expect do
          described_class.send_summaries
        end.to change(ReminderLog, :count).by(1)

        reminder_log = ReminderLog.last
        expect(reminder_log.user).to eq(user)
        expect(reminder_log.category).to eq('reaction_summary')
        expect(reminder_log.read_at).not_to be_nil
      end
    end

    context '通知設定が無効な場合' do
      before do
        user.update!(is_reaction_summary: false)
        create(:reaction, post: post, user: other_user, stamp: 'thumbs_up', created_at: Time.current)
      end

      it '通知を送信しないこと' do
        described_class.send_summaries
        expect(WebPushService).not_to have_received(:send_notification)
      end
    end

    context 'リアクションがない場合' do
      it '通知を送信しないこと' do
        described_class.send_summaries
        expect(WebPushService).not_to have_received(:send_notification)
      end
    end

    context '過去のリアクションのみの場合' do
      before do
        create(:reaction, post: post, user: other_user, stamp: 'thumbs_up', created_at: 1.day.ago)
      end

      it '通知を送信しないこと' do
        described_class.send_summaries
        expect(WebPushService).not_to have_received(:send_notification)
      end
    end
  end
end
