# ポートフォリオ閲覧モード（ゲスト機能）実装詳細資料

このドキュメントは、採用担当者やゲストユーザー向けに実装された「ポートフォリオ閲覧モード」の全容、設計思想、コード変更点を詳細にまとめたものです。

## 1. 概要と設計思想

### 目的

Google アカウントを持たない（または連携したくない）ユーザーに対し、アプリの魅力を最大限に伝えるための「体験版」モードを提供する。

### コアコンセプト

1.  **リッチなデータ体験**: 空っぽの状態で始めるのではなく、管理者のデータを複製して「3 ヶ月使い込んだ状態」を再現する。
2.  **安全性**: ゲストは閲覧のみとし、投稿や破壊的な操作を禁止する。また、本物のユーザーデータ（個人情報）は管理画面等で見せない。
3.  **Google Fit 不要**: 外部 API に依存せず、プログラム内で仮想の歩数データを生成してグラフ等を機能させる。

## 2. 実装詳細

### A. ユーザー管理と認証 (`User` Model & Session)

**変更ファイル:**

- `app/models/user.rb`
- `app/controllers/users/sessions_controller.rb`

#### ゲストユーザー作成ロジック (`User.create_portfolio_guest`)

1.  **クローン元の選定**:
    - 本番環境での運用を想定し、`User.find_by(id: 2)` を最優先でコピー元とする。
    - 存在しない場合は `User.admin.first`、それもなければ `create_fallback_guest` で最低限のダミーを作成。
2.  **データコピー**:
    - **期間**: 直近 3 ヶ月分に限定。
    - **対象**: `Walk` (散歩記録), `Post` (投稿), `UserAchievement` (実績)。
    - **手法**: `insert_all` を使用して SQL レベルで一括挿入し、パフォーマンスを確保。バリデーションをスキップすることで高速化している点に注意。
3.  **自動削除**:
    - `User.cleanup_old_guests` により、作成から 24 時間経過したゲスト（`role: :guest`）を削除。

#### 認証フロー

- ゲストログインボタン押下 → `Users::SessionsController#new_guest`
- ログイン後、セッションが維持される間は通常の Devise ユーザーとして振る舞う。
- ログアウト時 (`destroy`)、即座にそのゲストユーザーレコードを DB から削除する。

### B. Google Fit 連携シミュレーション (`GoogleFitService`)

**変更ファイル:**

- `app/services/google_fit_service.rb`
- `app/models/user.rb`

#### トークン検証のモック化:

- `User#google_token_valid?` を修正し、`guest?` なら常に `true` を返すように変更。これにより、設定画面等で「連携済み」と表示される。

#### データ取得のインターセプト:

- `GoogleFitService#fetch_activities` 内でゲスト判定を行う。
- ゲストの場合、API クライアントの初期化をスキップし、`fetch_dummy_activities` メソッドを呼び出す。

#### ダミーデータ生成ロジック:

- 期間中の各日について、`5000 + rand(-1000..3000)` 歩を生成。
- 距離、カロリー、活動時間も歩数から概算して生成。

### C. 管理画面の閲覧制限 (`Admin::DashboardController`)

**変更ファイル:**

- `app/controllers/admin/dashboard_controller.rb`
- `app/views/admin/dashboard/index.html.erb`

#### アクセス制御:

- `require_admin_or_guest` フィルタを追加。

#### データ隠蔽（Controller 層）:

- ゲストアクセス時、`@recent_users` や `@popular_posts` に本物の ActiveRecord オブジェクトを渡さず、`OpenStruct` で作成したダミーオブジェクトを渡す。
- これにより、万が一ビュー側で漏洩があっても、実データはメモリ上に存在しない。
- グローバル統計（総ユーザー数など）は、賑やかしとして実数（または固定値）を表示。

#### UI 制限（View 層）:

- 機密情報エリアに `relative overflow-hidden` と条件付きクラス `blur-sm` (ぼかし) を適用。
- その上に「🔒 Restricted」等のオーバーレイを表示し、操作できないことを視覚的に伝える。

### D. 投稿機能の制限 (`PostsController`)

**変更ファイル:**

- `app/controllers/posts_controller.rb`
- `app/views/posts/index.html.erb`

#### サーバーサイド:

- `create` アクションの冒頭で `if current_user.guest?` をチェックし、投稿リクエストがあれば強制リダイレクト＆アラート表示。

#### フロントエンド:

- タイムライン上部の「新規投稿フォーム」を非表示にし、代わりに「ポートフォリオ閲覧モード中は投稿できません」というバナーを表示。

### E. ランキングの可視性制御 (`User`, `RankingsController`)

**変更ファイル:**

- `app/models/user.rb`
- `app/controllers/rankings_controller.rb`

#### スコープ分離 (`User.ranking_for`):

- **ゲスト用**: 自分を含む全ユーザーを表示（自分が何位か確認したい需要に応える）。
- **一般ユーザー用**: `where.not(role: :guest)` でゲストを除外（ランキングがゲストだらけになるのを防ぐ）。

#### キャッシュ戦略:

- ランキング計算は重いためキャッシュしているが、見る人によって中身が異なるようになった。
- キャッシュキーに `viewer_role` (guest/general) を追加し、キャッシュ汚染を防ぐ。

## 3. 検証済みのテスト仕様

以下の System Spec により、機能の正しさを保証しています。修正時はこれらがパスすることを確認してください。

- **`spec/system/guest_login_system_spec.rb`**

  - ゲストログインができること。
  - ログアウト後にユーザーデータが消えること。

- **`spec/system/guest_admin_dashboard_spec.rb`**

  - ゲストが管理画面に入れること。
  - 重要なリストが「ぼかし」表示されていること。
  - ダミーテキスト（"ダミーユーザー"など）が表示されていること。
  - 他の管理ページへのアクセスが拒否されること。

- **`spec/system/guest_google_fit_spec.rb`**

  - Google Fit 連携状態が有効 (`true`) であること。
  - API 経由（サービスメソッド）で歩数データが取得できること。

- **`spec/system/guest_mode_enhancement_spec.rb`**
  - 投稿一覧は見れるが、投稿フォームがないこと。
  - 具体的なデータ作成（Walk 等）を伴うランキング表示において、一般ユーザーからはゲストが見えず、ゲストからは自分が見えること。

## 4. 今後の拡張・保守に関する注意点

1.  **コピー元のユーザー ID**:
    - 現在 `User.find_by(id: 2)` をハードコード気味に優先しています（`user.rb:115`）。環境に合わせて変更するか、環境変数化 (`ENV['DEMO_SOURCE_USER_ID']`) することを検討してください。
2.  **非同期ジョブ**:
    - `GenerateRankingOgpImageJob` など、バックグラウンドジョブがゲストユーザーに対しても走る設計になっています。リソース節約のため、ゲストの場合はジョブ発行をスキップする等のチューニングの余地があります。
3.  **DB パフォーマンス**:
    - ゲスト作成時の `insert_all` は高速ですが、関連テーブルが増えた場合（例: コメント機能など）、手動で追記する必要があります。`deep_cloneable` gem などの導入も検討の価値があります。
