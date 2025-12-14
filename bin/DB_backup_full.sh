#!/bin/bash
set -e

# プロジェクトルートディレクトリに移動
cd "$(dirname "$0")/.."

# バックアップディレクトリの作成
mkdir -p backups

# 環境変数の読み込み（.env.backupが存在する場合）
if [ -f .env.backup ]; then
  source .env.backup
fi

# DATABASE_URLの確認
if [ -z "$DATABASE_URL" ]; then
  echo "❌ エラー: DATABASE_URLが設定されていません。.env.backupを確認してください。"
  exit 1
fi

# 日付ごとのファイル名設定
FILENAME="backups/backup_full_$(date +%Y%m%d_%H%M%S).sql"

echo "📦 本番DBの完全バックアップを開始します..."
echo "   対象: 全スキーマ (public, auth, storage, etc.)"
echo "   保存先: $FILENAME"

# バックアップ実行
# --no-owner --no-acl: リストア時の権限エラーを防ぐために所有者情報を除外
pg_dump "$DATABASE_URL" --no-owner --no-acl > "$FILENAME"

echo "✅ バックアップが完了しました！"
ls -lh "$FILENAME"
