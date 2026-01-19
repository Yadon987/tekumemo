# Users テーブル正規化リファクタリング計画

## 目的

肥大化した `users` テーブル（27カラム）の責務分離による可読性・保守性・メモリ効率の向上。

## 変更内容

`users` テーブルを以下の4テーブルに分割・正規化を行う。

1. **`users`** (認証・権限): Devise認証、権限管理のみに特化
2. **`google_accounts`** (外部連携): Google認証トークン・有効期限等の分離
3. **`user_settings`** (設定): 通知設定、目標距離などの分離
4. **`user_profiles`** (表示): ユーザー名、アバター情報の分離

## カラム移動計画

| カテゴリ                     | カラム名                                                                                                    | 移動先                        |
| :--------------------------- | :---------------------------------------------------------------------------------------------------------- | :---------------------------- |
| 🔐 **認証コア (Devise必須)** | email, encrypted_password, reset_password_token, reset_password_sent_at, remember_created_at                | **users (残す)**              |
| 🛤 **Devise Trackable**      | sign_in_count, current_sign_in_at, last_sign_in_at, current_sign_in_ip, last_sign_in_ip                     | **users (残す)**              |
| 🛡 **権限**                  | role                                                                                                        | **users (残す)**              |
| 👤 **プロフィール**          | name, avatar_url, avatar_type                                                                               | 🚀 **user_profiles (新規)**   |
| 🔑 **Google OAuth**          | google_uid, google_token, google_refresh_token, google_expires_at                                           | 🚀 **google_accounts (新規)** |
| ⚙️ **ユーザー設定**          | goal_meters, is_walk_reminder, walk_reminder_time, is_inactive_reminder, inactive_days, is_reaction_summary | 🚀 **user_settings (新規)**   |
| 🕒 **タイムスタンプ**        | created_at, updated_at                                                                                      | **users (残す)**              |

## 期待される効果

- **メモリ使用量の削減**: 認証時に巨大なトークンや不要な設定値をロードしない
- **責務の明確化**: "Fat User Model" を解消し、機能ごとのクラス設計へ移行
- **データ容量の最適化**: 外部連携未使用ユーザーの無駄なレコード作成を防止

## 新規テーブル設計

### google_accounts テーブル

```ruby
create_table :google_accounts do |t|
  t.references :user, null: false, foreign_key: true, index: { unique: true }
  t.string :google_uid, null: false
  t.text :google_token
  t.text :google_refresh_token
  t.datetime :google_expires_at
  t.timestamps
end
```

### user_settings テーブル

```ruby
create_table :user_settings do |t|
  t.references :user, null: false, foreign_key: true, index: { unique: true }
  t.integer :goal_meters, default: 3000, null: false
  t.boolean :is_walk_reminder, default: false, null: false
  t.time :walk_reminder_time, default: '19:00'
  t.boolean :is_inactive_reminder, default: true, null: false
  t.integer :inactive_days, default: 3, null: false
  t.boolean :is_reaction_summary, default: true, null: false
  t.timestamps
end
```

### user_profiles テーブル

```ruby
create_table :user_profiles do |t|
  t.references :user, null: false, foreign_key: true, index: { unique: true }
  t.string :name, null: false
  t.string :avatar_url
  t.integer :avatar_type, default: 0, null: false
  t.timestamps
end
```

### users テーブル（最終形）

```ruby
create_table :users do |t|
  # 認証コア (Devise)
  t.string :email, default: "", null: false
  t.string :encrypted_password, default: "", null: false
  t.string :reset_password_token
  t.datetime :reset_password_sent_at
  t.datetime :remember_created_at

  # Trackable
  t.integer :sign_in_count, default: 0, null: false
  t.datetime :current_sign_in_at
  t.datetime :last_sign_in_at
  t.string :current_sign_in_ip
  t.string :last_sign_in_ip

  # 権限管理
  t.integer :role, default: 0, null: false

  t.timestamps
end
```

## 実装フェーズ

| Phase   | 対象            | リスク | 工数目安 |
| :------ | :-------------- | :----- | :------- |
| Phase 1 | google_accounts | 低     | 2-3時間  |
| Phase 2 | user_settings   | 中     | 3-4時間  |
| Phase 3 | user_profiles   | 高     | 4-6時間  |
| 最終    | 旧カラム削除    | 低     | 1時間    |

## 補足

- 正規化に伴う管理用カラム（ID等）の追加により、物理カラム総数は増加（27→37）
- N+1問題への対策（`includes` 追加）および既存機能との互換性を確保して実装を実施
- `is_admin` カラムは `role` に統合済みのため、最終フェーズで削除
