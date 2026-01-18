require 'rails_helper'

RSpec.describe GeneratePostOgpImageJob, type: :job do
  let(:dummy_image_data) { "\xFF\xD8\xFF\xE0\x00\x10JFIF" } # JPEGマジックナンバー

  before do
    allow_any_instance_of(RpgCardGeneratorService).to receive(:generate).and_return(dummy_image_data)
  end

  describe '#perform' do
    let(:user) { create(:user) }
    let(:post) { create(:post, user: user) }

    it 'OGP画像を生成して添付すること' do
      expect(post.ogp_image).not_to be_attached

      # ジョブ実行
      GeneratePostOgpImageJob.perform_now(post)

      post.reload
      expect(post.ogp_image).to be_attached
      expect(post.ogp_image.filename.to_s).to eq "post_#{post.id}_ogp.jpg"
    end

    it '既に画像がある場合は生成しないこと' do
      # ダミー画像を添付
      post.ogp_image.attach(io: StringIO.new('dummy'), filename: 'dummy.jpg', content_type: 'image/jpeg')

      expect(RpgCardGeneratorService).not_to receive(:new)

      GeneratePostOgpImageJob.perform_now(post)
    end
  end
end
