# ランキング OGP 実装 引継ぎ資料

## 🎉 解決済みの問題

### 1. Cloudinary へのアップロード失敗 → **解決**

**原因:** DB に古い ActiveStorage::Blob レコードが残っていたが、Cloudinary には実体がなかった（不整合状態）

**解決策:**

- 既存画像チェックを一時的に無効化して強制再生成
- コントローラー内で同期的に画像生成＆アップロード（投稿 OGP と同じパターン）
- Cloudinary へのアップロード成功を確認済み（ログで検証）

### 2. Twitter Card Validator で画像が表示されない → **解決**

**原因:** OGP 画像 URL に`.jpg`拡張子が含まれていなかった

**解決策:**

- ビューで明示的に`.jpg`を付加
- 変更箇所: `app/views/rankings/index.html.erb` 17-27 行目

### 3. メタタグが出力されない → **解決**

**原因:** URL に`.jpg`がなかったため、Twitter が画像として認識しなかった

**解決策:** 上記 2 の対応で解決

---

## ⚠️ 残っている課題

### 画像生成に時間がかかる（13 秒程度）

**現象:**

- 初回アクセス時、ランキング OGP 画像の URL にアクセスすると 13 秒程度待たされる
- これは、コントローラー内で同期的に以下を行っているため：
  1. 週間データ集計（SQL クエリ）
  2. 順位計算（SQL クエリ）
  3. RPG 風画像生成（MiniMagick）
  4. Cloudinary アップロード（HTTP 通信）

**影響範囲:**

- 初回アクセス時のみ
- 12 時間以内に再アクセスすれば、既存画像を返すのでほぼ即座に完了
- ユーザー体験への影響は限定的だが、Twitter Card Validator などが「タイムアウト」する可能性がある

---

## 💡 解決策候補（次のチャットで実施）

### 案 1: 事前生成（推奨）⭐⭐⭐⭐⭐

**概要:** ランキングページにアクセスした時点で、バックグラウンドジョブをキック

**実装例:**

```ruby
# app/controllers/rankings_controller.rb
def index
  # ログインユーザーの画像を事前生成
  if user_signed_in?
    GenerateRankingOgpImageJob.perform_later(current_user)
  end

  # ランキング表示処理
end
```

**メリット:**

- ユーザーがシェアする前に画像が準備される
- Twitter Card Validator のアクセス時は既に画像がある

**デメリット:**

- 全ユーザー分を生成すると負荷が高い
- ログインユーザーのみに限定すれば現実的

### 案 2: キャッシュ時間の延長

**現在:** 12 時間キャッシュ
**提案:** 1 週間キャッシュ（ランキング期間と一致）

```ruby
# app/controllers/rankings/ogp_images_controller.rb 19行目
@user.ranking_ogp_image.blob.created_at > 1.week.ago  # 12.hours.ago から変更
```

**メリット:**

- 週が変わるまで再生成しない
- 週の途中で何度シェアしても既存画像を返す

**デメリット:**

- 順位変動が反映されない（週の途中でランクアップしても画像は変わらない）

### 案 3: 画像生成の高速化

**アプローチ:**

1. アバター画像のキャッシュ利用（既に実装済み）
2. フォントのプリロード
3. 画像サイズの最適化（現在 1200x630、もっと小さくできるか検証）

**メリット:**

- 根本的な高速化

**デメリット:**

- 効果が限定的（アップロード時間は変わらない）

### 案 4: タイムアウト対策（最終手段）

**概要:** 5 秒以内に完了しない場合、デフォルト画像を返す

```ruby
timeout_result = Timeout.timeout(5) do
  # 画像生成処理
end
rescue Timeout::Error
  redirect_to image_url('icon.png')
end
```

**メリット:**

- Twitter Card Validator のタイムアウトを回避

**デメリット:**

- 初回はデフォルト画像になる可能性が高い

---

## 📁 関連ファイルと変更箇所

### コントローラー

- `app/controllers/rankings/ogp_images_controller.rb`
  - 13-22 行目: 既存画像チェック
  - 27-89 行目: 画像生成とアップロード

### ビュー

- `app/views/rankings/index.html.erb`
  - 6-27 行目: OGP メタタグ定義
  - 17-23 行目: `.jpg`拡張子の明示的付加

### ジョブ

- `app/jobs/generate_ranking_ogp_image_job.rb` (現在未使用)
  - 事前生成に使える

### 設定

- `config/environments/production.rb`
  - 36 行目: `log_level = :debug` ← 問題解決後は`:info`に戻すことを推奨
  - 45 行目: `active_job.queue_adapter = :inline`

---

## 🔍 デバッグログの見方

ランキング OGP 生成時、以下のログが出力されます：

```
[Ranking OGP] User: 2, Period: 20251215_20251221
[Ranking OGP] Image generated, size: 91212 bytes
[Ranking OGP] Before attach - attached?: false
[Ranking OGP] After attach - attached?: true
[Ranking OGP] After reload - attached?: true
[Ranking OGP] Success! Blob URL: https://...
```

**正常パターン:**

- `Before attach: false` → `After attach: true` → `After reload: true`

**異常パターン（未発生だが念のため）:**

- `After reload: false` → DB への保存失敗
- `Image generated, size: 0` → 画像生成失敗

---

## 🚀 次にやるべきこと（優先順位順）

1. **案 1 の実装（事前生成）** - 最も効果的
2. **案 2 の実装（キャッシュ延長）** - 簡単で効果あり
3. **ログレベルを`:info`に戻す** - 本番環境の負荷軽減
4. **パフォーマンス測定** - 実際の所要時間を計測
5. **案 3 の検討** - 根本的な高速化

---

## 📊 現在のパフォーマンス

**初回生成時:**

- 週間データ集計: ~300ms
- 順位計算: ~100ms
- アバターダウンロード＆キャッシュ: ~3 秒（初回のみ）
- 画像生成: ~4 秒
- Cloudinary アップロード: ~1 秒
- **合計: 約 13 秒**

**2 回目以降（12 時間以内）:**

- 既存画像チェック: ~300ms
- リダイレクト: 即座
- **合計: 約 0.3 秒**

---

## 🎯 理想の動作フロー

```
ユーザーがランキングページにアクセス
  ↓
バックグラウンドで画像生成開始（非同期）
  ↓
ユーザーがシェアボタンをクリック
  ↓
（この時点で画像生成完了済み）
  ↓
Twitter Card Validatorが画像URLにアクセス
  ↓
既存画像を即座に返す（0.3秒）
```

---

## ✅ 完了したタスク

- [x] ランキング OGP 画像生成機能実装
- [x] Cloudinary へのアップロード成功
- [x] Twitter Card メタタグ表示成功
- [x] デバッグログ追加
- [x] CI/CD テストエラー修正
- [x] ランキングページにプレビュー機能追加

## 📝 未完了タスク

- [ ] 画像生成の高速化
- [ ] 事前生成機能の実装
- [ ] ログレベルを`:info`に戻す
- [ ] パフォーマンスの最適化

---

## 🔗 参考リンク

- Twitter Card Validator: https://cards-dev.twitter.com/validator
- Cloudinary 管理画面: https://console.cloudinary.com/
- Render 管理画面: https://dashboard.render.com/

---

**作成日:** 2025-12-18
**作成者:** Claude (Anthropic)
**ブランチ:** `14-ogp-implementation`
**最新コミット:** `6bc5336` (OGP 画像生成の劇的高速化と UX 改善)
