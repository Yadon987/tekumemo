class OptimizeUsersTableColumns < ActiveRecord::Migration[7.2]
  # レビュー指摘対応: DBカラムの最適化
  # - avatar_url: Google画像URLが255文字を超える可能性があるためtext型に変更
  # - name: ユーザー名に255文字は不要なため50文字に制限（ストレージ効率化）
  def up
    # avatar_url を string(255) から text に変更
    # text型はPostgreSQLでは無制限だが、モデル側でバリデーションを追加する
    change_column :users, :avatar_url, :text

    # name を string(255) から string(50) に変更
    # 本番データで50文字超は0件であることを確認済み
    change_column :users, :name, :string, limit: 50
  end

  def down
    # ロールバック時は元のstring型に戻す
    # avatar_url: text -> string（2048文字超のデータがあると失敗する可能性あり）
    change_column :users, :avatar_url, :string

    # name: string(50) -> string（制限解除）
    change_column :users, :name, :string
  end
end
