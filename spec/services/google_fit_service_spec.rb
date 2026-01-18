require 'rails_helper'
require 'google/apis/fitness_v1'

RSpec.describe GoogleFitService, type: :service do
  let(:user) do
    create(:user, google_token: 'token', google_refresh_token: 'refresh_token', google_expires_at: 1.hour.from_now)
  end
  let(:service) { described_class.new(user) }
  let(:fitness_service) { instance_double(Google::Apis::FitnessV1::FitnessService) }
  let(:auth_client) { instance_double(Signet::OAuth2::Client) }

  before do
    allow(Google::Apis::FitnessV1::FitnessService).to receive(:new).and_return(fitness_service)
    allow(fitness_service).to receive(:authorization=)
    allow(user).to receive(:google_token_valid?).and_return(true)

    # Signet::OAuth2::Client のモック
    allow(Signet::OAuth2::Client).to receive(:new).and_return(auth_client)
    allow(auth_client).to receive(:refresh!)
    allow(auth_client).to receive(:access_token).and_return('new_token')
    allow(auth_client).to receive(:expires_at).and_return(Time.now + 3600)
  end

  describe '#fetch_activities' do
    let(:start_date) { Date.current }
    let(:end_date) { Date.current }

    # === 値オブジェクト ===
    let(:step_val_obj) { double(int_val: 1000) }
    let(:distance_val_obj) { double(fp_val: 1500.0) } # 1500m
    let(:calorie_val_obj) { double(fp_val: 500.0) }

    # === アクティビティセグメントリクエスト用のモック ===
    # データセットの順序: Steps, Distance, Calories
    let(:act_step_point) { double(value: [step_val_obj]) }
    let(:act_distance_point) { double(value: [distance_val_obj]) }
    let(:act_calorie_point) { double(value: [calorie_val_obj]) }

    let(:act_step_dataset) { double(point: [act_step_point]) }
    let(:act_distance_dataset) { double(point: [act_distance_point]) }
    let(:act_calorie_dataset) { double(point: [act_calorie_point]) }

    # 1時間（60分）の歩行セグメント
    let(:segment_start_millis) { start_date.beginning_of_day.to_i * 1000 }
    let(:segment_end_millis) { segment_start_millis + 3_600_000 } # 1時間後

    let(:activity_bucket) do
      double(
        start_time_millis: segment_start_millis,
        end_time_millis: segment_end_millis,
        activity: 7, # Walking
        dataset: [act_step_dataset, act_distance_dataset, act_calorie_dataset]
      )
    end
    let(:activity_segments_response) { double(bucket: [activity_bucket]) }

    before do
      # アクティビティセグメントのレスポンスを返す
      allow(fitness_service).to receive(:aggregate_dataset).and_return(activity_segments_response)
    end

    it '正しくデータを取得して整形すること' do
      result = service.fetch_activities(start_date, end_date)
      data = result[:data][start_date]

      # 歩数: アクティビティセグメントから (1000)
      # 距離: アクティビティセグメントから (1500m -> 1.5km)
      # カロリー: アクティビティセグメントから (500)
      # 時間: セグメント時間 (60分)

      expect(data[:steps]).to eq 1000
      expect(data[:distance]).to eq 1.5
      expect(data[:calories]).to eq 500
      expect(data[:duration]).to eq 60 # セグメント時間（1時間）
    end

    context 'APIエラーが発生した場合' do
      context '権限不足による403エラーの場合' do
        before do
          error = Google::Apis::ClientError.new('insufficientPermission: Request had insufficient authentication scopes.')
          allow(error).to receive(:status_code).and_return(403)
          allow(fitness_service).to receive(:aggregate_dataset).and_raise(error)
        end

        it 'トークンはクリアされず、api_errorを返すこと' do
          expect(user).not_to receive(:update_columns)
          result = service.fetch_activities(start_date, end_date)
          expect(result[:error]).to eq :api_error
          expect(result[:message]).to include('権限が不足')
        end
      end

      context 'その他の403エラーの場合' do
        before do
          error = Google::Apis::ClientError.new('Token expired')
          allow(error).to receive(:status_code).and_return(403)
          allow(fitness_service).to receive(:aggregate_dataset).and_raise(error)
        end

        it 'トークンがクリアされ、auth_expiredを返すこと' do
          expect(user).to receive(:update_columns).with(hash_including(google_token: nil))
          result = service.fetch_activities(start_date, end_date)
          expect(result[:error]).to eq :auth_expired
        end
      end

      context '一般的なAPIエラーの場合' do
        before do
          allow(fitness_service).to receive(:aggregate_dataset).and_raise(Google::Apis::ClientError.new('API Error'))
        end

        it 'エラーハッシュを返すこと' do
          result = service.fetch_activities(start_date, end_date)
          expect(result).to include(error: :api_error)
        end
      end
    end
  end
end
