require 'rails_helper'

RSpec.describe 'WalksPagination', type: :request do
  let(:user) { User.create!(email: 'pagination_test@example.com', password: 'password', name: 'ページネーション太郎') }

  before do
    # 15件のデータを作成
    # 場所0: 今日, 場所1: 昨日 ... 場所14: 14日前
    15.times do |i|
      Walk.create!(
        user: user,
        walked_on: Date.current - i.days,
        location: "場所#{i}",
        kilometers: 1.0,
        minutes: 10,
        steps: 1000,
        calories: 50
      )
    end

    # ログイン処理
    sign_in user
  end

  it 'ページネーションが表示され、ページ遷移ができること' do
    # 1ページ目にアクセス
    get walks_path, headers: { 'Host' => 'localhost' }
    expect(response).to have_http_status(:success)

    # 1ページ目の確認（日付が新しい順なので、場所0〜9が表示されるはず）
    expect(response.body).to include('場所0') # 今日の記録
    expect(response.body).to include('場所9') # 9日前の記録
    expect(response.body).not_to include('場所10') # 10日前の記録（2ページ目）

    # ページネーションのリンクが存在することを確認
    expect(response.body).to include('role="navigation"')
    expect(response.body).to include('aria-label="pager"')

    # 2ページ目へアクセス
    get walks_path(page: 2), headers: { 'Host' => 'localhost' }
    expect(response).to have_http_status(:success)

    # 2ページ目の確認
    expect(response.body).to include('場所10')
    expect(response.body).to include('場所14')
    expect(response.body).not_to include('場所0')
  end
end
