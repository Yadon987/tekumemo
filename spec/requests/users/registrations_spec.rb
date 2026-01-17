require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  let(:user) { create(:user) }
  let(:avatar_path) { Rails.root.join('spec/fixtures/files/avatar.jpg') }
  let(:avatar_file) { fixture_file_upload(avatar_path, 'image/jpeg') }

  before do
    sign_in user
  end

  describe 'PUT /users' do
    context 'アバター画像のアップロード' do
      it "画像をアップロードしてアバタータイプを'uploaded'に更新できること" do
        put user_registration_path, params: {
          user: {
            uploaded_avatar: avatar_file,
            avatar_type: 'uploaded',
            current_password: user.password
          }
        }

        user.reload
        expect(user.uploaded_avatar).to be_attached
        expect(user.avatar_type).to eq('uploaded')
        expect(response).to redirect_to(edit_user_registration_path)
      end
    end

    context 'アバタータイプの切り替え' do
      before do
        # 事前に画像をアップロードしておく
        user.uploaded_avatar.attach(io: File.open(avatar_path), filename: 'avatar.jpg', content_type: 'image/jpeg')
        user.update!(avatar_type: :uploaded)
      end

      it "アバタータイプを'default'に切り替えられること" do
        put user_registration_path, params: {
          user: {
            avatar_type: 'default',
            current_password: user.password
          }
        }

        expect(user.reload.avatar_type).to eq('default')
        # 画像自体は消えていないことを確認
        expect(user.uploaded_avatar).to be_attached
      end

      it "アバタータイプを'uploaded'に戻せること" do
        user.update!(avatar_type: :default)

        put user_registration_path, params: {
          user: {
            avatar_type: 'uploaded',
            current_password: user.password
          }
        }

        expect(user.reload.avatar_type).to eq('uploaded')
      end
    end
  end

  describe 'DELETE /users/uploaded_avatar' do
    before do
      user.uploaded_avatar.attach(io: File.open(avatar_path), filename: 'avatar.jpg', content_type: 'image/jpeg')
      user.update!(avatar_type: :uploaded)
    end

    it "アップロード画像を削除し、アバタータイプを'default'にリセットすること" do
      delete delete_user_uploaded_avatar_path

      user.reload
      expect(user.uploaded_avatar).not_to be_attached
      expect(user.avatar_type).to eq('default')
      expect(response).to redirect_to(edit_user_registration_path)
      expect(flash[:notice]).to eq('アップロード画像を削除しました')
    end
  end
end
