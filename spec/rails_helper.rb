# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
# Uncomment the line below in case you have `--require rails_helper` in the `.rspec` file
# that will avoid rails generators crashing because migrations haven't been run yet
# return unless Rails.env.test?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Ensures that the test database schema matches the current schema file.
# If there are pending migrations it will invoke `db:test:prepare` to
# recreate the test database by loading the schema.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

require 'capybara/rails'
require 'capybara/cuprite'
require 'webmock/rspec'

# WebMockの設定: ローカルホストへの接続は許可する（システムテスト等のため）
WebMock.disable_net_connect!(allow_localhost: true)

# 並列実行時は負荷がかかるため、待機時間を長めに設定
Capybara.default_max_wait_time = 10

RSpec.configure do |config|
  # システムテストの設定
  config.before(:each, type: :system) do
    driven_by(:rack_test)
  end

  config.before(:each, type: :system, js: true) do
    driven_by(:cuprite, screen_size: [ 1400, 1400 ], options: {
      window_size: [ 1400, 1400 ],
      browser_options: {
        'no-sandbox' => nil,
        'disable-dev-shm-usage' => nil,
        'disable-gpu' => nil
      },
      process_timeout: 30, # タイムアウトを少し緩和
      timeout: 30,         # タイムアウトを少し緩和
      inspector: true,
      headless: true,
      # 高速化のために不要なリソースをブロック
      url_blacklist: [
        /fonts\.googleapis\.com/,
        /fonts\.gstatic\.com/,
        /analytics\.google\.com/,
        /www\.googletagmanager\.com/
      ]
    })
  end
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Warden::Test::Helpers
  config.before(:suite) do
    Warden.test_mode!
  end
  config.after :each do
    Warden.test_reset!
  end

  # メール送信を高速化（メモリ内で完結）
  config.before(:each) do
    ActionMailer::Base.deliveries.clear
    stub_request(:any, /cloudinary\.com/).to_return(status: 200, body: "", headers: {})
  end

  config.include FactoryBot::Syntax::Methods
  config.include ActiveSupport::Testing::TimeHelpers
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # DatabaseCleanerの設定
  # Rails標準のトランザクション管理を使用する
  config.use_transactional_fixtures = true

  # DatabaseCleanerの設定は削除（Rails標準機能で十分なため）

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails uses metadata to mix in different behaviours to your tests,
  # for example enabling you to call `get` and `post` in request specs. e.g.:
  #
  #     RSpec.describe UsersController, type: :request do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/8-0/rspec-rails
  #
  # You can also this infer these behaviours automatically by location, e.g.
  # /spec/models would pull in the same behaviour as `type: :model` but this
  # behaviour is considered legacy and will be removed in a future version.
  #
  # To enable this behaviour uncomment the line below.
  # config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end
