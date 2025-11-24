require 'rails_helper'

RSpec.describe User, type: :model do
  describe '.from_omniauth' do
    # OmniAuthのモックデータを作成
    # 実際のGoogle認証の代わりに、このハッシュデータを使用します
    let(:auth_hash) do
      OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '123456789',
        info: {
          email: 'test@example.com'
        },
        credentials: {
          token: 'mock_token',
          refresh_token: 'mock_refresh_token',
          expires_at: Time.now.to_i + 3600
        }
      })
    end

    context 'ユーザーが既に存在する場合' do
      it 'そのユーザーを返し、Google認証情報を更新すること' do
        # 事前にユーザーを作成（FactoryBotがないためcreate!を使用）
        user = User.create!(
          email: 'test@example.com',
          password: 'password123',
          google_uid: 'old_uid'
        )

        # メソッド実行
        result_user = User.from_omniauth(auth_hash)

        # 検証
        expect(result_user).to eq(user) # 同じユーザーオブジェクトが返されるか
        expect(result_user.google_uid).to eq('123456789') # UIDが更新されているか
        expect(result_user.google_token).to eq('mock_token') # トークンが更新されているか
      end
    end

    context 'ユーザーが存在しない場合' do
      it '新しいユーザーを作成すること' do
        # ユーザー数が増えることを検証
        expect {
          User.from_omniauth(auth_hash)
        }.to change(User, :count).by(1)

        # 作成されたユーザーの属性を検証
        new_user = User.last
        expect(new_user.email).to eq('test@example.com')
        expect(new_user.google_uid).to eq('123456789')
      end
    end
  end
end
