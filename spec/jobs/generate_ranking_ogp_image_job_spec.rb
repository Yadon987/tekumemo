require 'rails_helper'

RSpec.describe GenerateRankingOgpImageJob, type: :job do
  let(:dummy_image_data) { "\xFF\xD8\xFF\xE0\x00\x10JFIF" } # JPEGマジックナンバー

  before do
    allow_any_instance_of(RpgCardGeneratorService).to receive(:generate).and_return(dummy_image_data)
  end

  describe '#perform' do
    let(:user) { create(:user) }

    it 'ランキングOGP画像を生成して添付すること' do
      expect(user.ranking_ogp_image).not_to be_attached

      # ジョブ実行
      GenerateRankingOgpImageJob.perform_now(user)

      user.reload
      expect(user.ranking_ogp_image).to be_attached
      expect(user.ranking_ogp_image.filename.to_s).to match(/ranking_#{user.id}_\d{8}_\d{8}\.jpg/)
    end

    it '既に画像がある場合は生成しないこと' do
      # 今週のperiod_keyを計算
      start_date = Date.current.beginning_of_week
      end_date = Date.current.end_of_week
      period_key = "#{start_date.strftime('%Y%m%d')}_#{end_date.strftime('%Y%m%d')}"

      # ダミー画像を添付
      user.ranking_ogp_image.attach(io: StringIO.new('dummy'), filename: "ranking_#{user.id}_#{period_key}.jpg",
                                    content_type: 'image/jpeg')

      expect(RpgCardGeneratorService).not_to receive(:new)

      GenerateRankingOgpImageJob.perform_now(user)
    end
  end
end
