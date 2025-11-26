#!/bin/bash
# backup_secrets.sh - 重要ファイルのバックアップスクリプト
# ~/workspace/tekumemo/backup_secrets.sh をコマンドで実行
# chmod +x ~/workspace/tekumemo/backup_secrets.sh 実行権限を付与

echo "🔄 バックアップを開始します..."

# プロジェクト名とタイムスタンプ
PROJECT_NAME=$(basename $(pwd))
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 統一バックアップディレクトリ
BACKUP_DIR=~/all_secrets_backup
mkdir -p "$BACKUP_DIR"

# 一時ディレクトリを作成
TEMP_DIR="/tmp/backup_${PROJECT_NAME}_${TIMESTAMP}"
mkdir -p "$TEMP_DIR"

echo "📂 プロジェクト: $PROJECT_NAME"

# ファイル検知フラグ
FILES_FOUND=false

# ==========================================
# 1. 環境変数ファイル群 (.env*)
# ==========================================
echo "🔑 環境変数を検索中..."
# .env.example や .erb を除外しつつ、.env で始まるファイルをすべて取得してコピー
find . -maxdepth 1 -name ".env*" ! -name "*.erb" ! -name ".env.example" | while read file; do
    cp "$file" "$TEMP_DIR/" && echo "✅ $file を追加"
    FILES_FOUND=true
done

# ==========================================
# 2. master.key
# ==========================================
if [ -f "config/master.key" ]; then
    # 復元時に分かりやすいよう config ディレクトリを作って配置
    mkdir -p "$TEMP_DIR/config"
    cp config/master.key "$TEMP_DIR/config/" && echo "✅ config/master.key を追加"
    FILES_FOUND=true
fi

# ==========================================
# 3. VSCode設定
# ==========================================
if [ -d ".vscode" ]; then
    # ディレクトリごとコピー
    cp -r .vscode "$TEMP_DIR/" && echo "✅ .vscodeディレクトリを追加"
    FILES_FOUND=true
fi

# ==========================================
# 4. ローカルストレージデータ (任意)
# ==========================================
if [ -d "storage" ]; then
    # .keep ファイルなどを除外してデータがあるか確認しても良いが、まるごとコピーが無難
    mkdir -p "$TEMP_DIR/storage"
    # エラー抑制のため || : を追加（空の場合対策）
    cp -r storage/* "$TEMP_DIR/storage/" 2>/dev/null || :
    echo "✅ storage (ローカルアップロードファイル) を追加"
    FILES_FOUND=true
fi

# ==========================================
# 5. SQLiteデータベース (任意)
# ==========================================
find . -maxdepth 1 -name "*.sqlite3" | while read db_file; do
    cp "$db_file" "$TEMP_DIR/" && echo "✅ $db_file (DB) を追加"
    FILES_FOUND=true
done

# ==========================================
# ZIP圧縮とクリーンアップ
# ==========================================
if [ "$FILES_FOUND" = true ]; then
    ZIP_FILE="$BACKUP_DIR/${PROJECT_NAME}_secrets_${TIMESTAMP}.zip"

    # 一時ディレクトリに移動してZIP化（パスを含めないため）
    cd "$TEMP_DIR"
    zip -r "$ZIP_FILE" . > /dev/null 2>&1
    cd - > /dev/null

    echo "🎉 バックアップ完了: $ZIP_FILE"
    echo "📦 ZIPファイルサイズ: $(du -h "$ZIP_FILE" | cut -f1)"
else
    echo "⚠️  バックアップ対象ファイルが見つかりませんでした"
fi

# 一時ディレクトリを削除
rm -rf "$TEMP_DIR"

echo "📁 全バックアップファイル:"
ls -la "$BACKUP_DIR"
