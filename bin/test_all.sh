#!/bin/bash
# ~/workspace/tekumemo/bin/test_all.sh をコマンドで実行
# chmod +x ~/workspace/tekumemo/bin/test_all.sh 実行権限を付与

# 目的: ファイル権限の修正、コードスタイルの修正/チェック、テスト実行を一括で行う

# 1. ファイル権限の修正
# chown -R $USER:$USER . : 現在のディレクトリ以下の全ファイルの所有者を現在のユーザーに変更
# パスワード入力はsudoersの設定（NOPASSWD: /bin/chown -R *）によりスキップされます
echo "--- 1/3: ファイル所有権の修正 (chown) ---"
sudo chown -R $USER:$USER .

# 成功確認
if [ $? -ne 0 ]; then
    echo "🚨 chown 実行エラー: sudoers設定または権限を確認してください。"
    exit 1
fi


# 2. RuboCopの実行と自動修正
# -a (auto-correct) をつけて、スタイルを自動修正
echo "--- 2/3: RuboCop実行と自動修正 ---"
bundle exec rubocop -a

# RuboCopがエラー（修正不能なエラー）で終了した場合、後続のテストは実行しない
if [ $? -ne 0 ]; then
    echo "⚠️ RuboCopで重大なスタイルエラーが検出されました。テストをスキップします。"
    exit 1
fi


# 3. RSpecの実行（標準実行）
# 並列実行は環境依存のエラーが出やすいため、安定した通常のRSpecを使用
echo "--- 3/3: RSpec実行 ---"
bundle exec rspec spec/

# 並列テストの結果確認
if [ $? -ne 0 ]; then
    echo ""
    echo "🚨 テストが失敗しました。"
    echo "AIエージェントに以下のログを共有し、修正を依頼してください。"
    exit 1
fi

echo "--- 全てのタスクが完了しました ---"
