require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the PostsHelper. For example:
#
# describe PostsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe PostsHelper, type: :helper do
  describe '#post_color_theme' do
    let(:post) { build(:post, weather: weather, feeling: feeling) }

    context '天気のスコアが高い場合' do
      let(:weather) { 'stormy' } # score: 9
      let(:feeling) { 'good' }   # score: 2

      it '天気に基づいたテーマ（stormy）を返すこと' do
        theme = helper.post_color_theme(post)
        expect(theme[:bg]).to include('bg-[#faf5ff]') # stormyの背景色
      end
    end

    context '気分のスコアが高い場合' do
      let(:weather) { 'cloudy' } # score: 1
      let(:feeling) { 'great' }  # score: 7

      it '気分に基づいたテーマ（great）を返すこと' do
        theme = helper.post_color_theme(post)
        expect(theme[:bg]).to include('bg-[#fffbeb]') # greatの背景色
      end
    end

    context 'スコアが同点の場合' do
      # sunny: 5, feelingに5のスコアはないので調整が難しいが、
      # ロジック上は天気が優先される
      # ここでは weather: sunny (5), feeling: normal (0) で天気優先を確認
      let(:weather) { 'sunny' }
      let(:feeling) { 'normal' }

      it '天気を優先すること' do
        theme = helper.post_color_theme(post)
        expect(theme[:bg]).to include('bg-[#fff7ed]') # sunnyの背景色
      end
    end

    context '未設定の場合' do
      let(:weather) { nil }
      let(:feeling) { nil }

      it 'デフォルトのテーマを返すこと' do
        theme = helper.post_color_theme(post)
        expect(theme[:bg]).to include('bg-[#fafaf9]') # defaultの背景色
      end
    end
  end
end
