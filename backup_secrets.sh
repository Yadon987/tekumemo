#!/bin/bash
# backup_secrets.sh - 重要ファイルのバックアップスクリプト
# ~/workspace/tekumemo/backup_secrets.sh  をコマンドで実行
# chmod +x ~/workspace/tekumemo/backup_secrets.sh  実行権限を付与

echo "🔄 バックアップを開始します..."

# バックアップ先ディレクトリを作成
BACKUP_DIR=~/app_secrets_backup/$(basename $(pwd))
mkdir -p "$BACKUP_DIR"

# 各ファイルをバックアップ（存在する場合のみ）
if [ -f ".env" ]; then
    cp .env "$BACKUP_DIR/" && echo "✅ .env をバックアップしました"
fi

if [ -f ".env.local" ]; then
    cp .env.local "$BACKUP_DIR/" && echo "✅ .env.local をバックアップしました"
fi

if [ -f "config/master.key" ]; then
    cp config/master.key "$BACKUP_DIR/" && echo "✅ master.key をバックアップしました"
fi

if [ -d ".vscode" ] && [ -f ".vscode/settings.json" ]; then
    mkdir -p "$BACKUP_DIR/.vscode"
    cp .vscode/settings.json "$BACKUP_DIR/.vscode/" && echo "✅ VSCode設定をバックアップしました"
fi

echo "🎉 バックアップ完了: $BACKUP_DIR"
echo "📁 バックアップ内容:"
ls -la "$BACKUP_DIR"
