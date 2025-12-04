# 開発日誌

## 2025-12-05

### Google 認証設定の修正

本番環境（特に Cloudflare 等のプロキシ下）での認証エラー（CSRF エラー）を解消するため、以下の設定を変更しました。

- `config/environments/production.rb`
  - `config.action_controller.forgery_protection_origin_check = false` を追加し、オリジンチェックを無効化（Cloudflare 対策）
- `config/initializers/session_store.rb`
  - `same_site` 設定を `:lax` に変更

### UI バグ修正

ユーザー設定画面（`/users/edit`）において、連携解除モーダルが画面中央に表示されない問題を修正しました。

- **原因**: モーダルが `backdrop-blur` 等のスタイルを持つ親要素内に配置されていたため、`fixed` 配置の基準がビューポートではなく親要素になっていた。
- **対応**: `content_for` を使用してモーダルの HTML を `body` 直下（レイアウトファイル側で制御）に移動させ、親要素のスタイルの影響を受けないようにした。

### テスト修正

- `spec/requests/stats_coming_soon_spec.rb`
  - ログイン処理が抜けていたためテストが失敗していた問題を修正。
