require 'rails_helper'

RSpec.describe "GoogleFit", type: :request do
  # テスト用ユーザーの作成
  let(:user) { FactoryBot.create(:user) }

  describe "GET /google_fit/daily_data" do
    context "ログインしていない場合" do
      it "ログインページにリダイレクトされること" do
        get google_fit_daily_data_path
        expect(response).to have_http_status(:found) # 302 Redirect
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログインしている場合" do
      before { sign_in user }

      context "Google連携していない（トークンが無効な）場合" do
        before do
          # トークンを持たない、または期限切れの状態にする
          user.update(google_token: nil, google_expires_at: nil)
        end

        it "401 Unauthorizedエラーとエラーメッセージが返ること" do
          get google_fit_daily_data_path

          expect(response).to have_http_status(:unauthorized)
          json = JSON.parse(response.body)
          expect(json["error"]).to include("連携してください")
        end
      end

      context "Google連携済みの場合" do
        # 有効なトークンを持つユーザーを作成
        let(:valid_user) {
          FactoryBot.create(:user,
            google_token: "valid_token",
            google_expires_at: 1.hour.from_now,
            google_refresh_token: "refresh_token"
          )
        }

        # モックオブジェクトの準備
        let(:mock_service) { instance_double("GoogleFitService") }

        before do
          sign_in valid_user
          # GoogleFitService.new が呼ばれたら、mock_service を返すように設定
          allow(GoogleFitService).to receive(:new).with(valid_user).and_return(mock_service)
        end

        context "データ取得に成功した場合" do
          before do
            # fetch_daily_data メソッドの戻り値を設定
            allow(mock_service).to receive(:fetch_daily_data).and_return({
              steps: 5000,
              distance: 3.5,
              duration: 45,
              calories: 200
            })
          end

          it "200 OKと取得したデータがJSONで返ること" do
            get google_fit_daily_data_path(date: "2025-12-01")

            expect(response).to have_http_status(:ok)

            json = JSON.parse(response.body)
            expect(json["steps"]).to eq(5000)
            expect(json["distance"]).to eq(3.5)
            expect(json["duration"]).to eq(45)
            expect(json["calories"]).to eq(200)
            expect(json["date"]).to eq("2025-12-01")
          end
        end

        context "データ取得に失敗した場合（nilが返ってきた場合）" do
          before do
            allow(mock_service).to receive(:fetch_daily_data).and_return(nil)
          end

          it "422 Unprocessable Entityとエラーメッセージが返ること" do
            get google_fit_daily_data_path

            expect(response).to have_http_status(:unprocessable_entity)
            json = JSON.parse(response.body)
            expect(json["error"]).to include("取得できませんでした")
          end
        end

        context "無効な日付形式が送信された場合" do
          it "400 Bad Requestが返ること" do
            # サービス呼び出し前にエラーになるはずだが、念のためモック設定
            allow(GoogleFitService).to receive(:new).and_return(mock_service)

            get google_fit_daily_data_path(date: "invalid-date")

            expect(response).to have_http_status(:bad_request)
            json = JSON.parse(response.body)
            expect(json["error"]).to include("無効な日付形式")
          end
        end
      end
    end
  end

  describe "GET /google_fit/status" do
    before { sign_in user }

    context "連携済みの場合" do
      before do
        user.update(google_token: "token", google_refresh_token: "refresh_token", google_expires_at: 1.hour.from_now)
      end

      it "connected: true とメールアドレスが返ること" do
        get google_fit_status_path

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["connected"]).to be true
        expect(json["email"]).to eq(user.email)
      end
    end

    context "未連携の場合" do
      before do
        user.update(google_token: nil)
      end

      it "connected: false が返ること" do
        get google_fit_status_path

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["connected"]).to be false
      end
    end
  end
end
