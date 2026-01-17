# OmniAuthのテストモード設定
OmniAuth.config.test_mode = true
OmniAuth.config.request_validation_phase = nil

# ログ出力を抑制（テスト実行時のノイズを減らす）
OmniAuth.config.logger = Logger.new('/dev/null')
