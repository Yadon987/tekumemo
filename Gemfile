source "https://rubygems.org"

gem "rails", "~> 7.2.3"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "jsbundling-rails"
gem "turbo-rails"
gem "stimulus-rails" # 追加
gem "jbuilder"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false
gem "devise"
gem "foreman"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection", "~> 1.0.2"
gem "google-apis-fitness_v1"
gem "simple_calendar", "~> 3.0"
gem "dotenv-rails"
gem "geocoder"
gem "kaminari"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "sqlite3", ">= 1.4"
  gem "capybara"
  gem "selenium-webdriver"
end

gem "rspec-rails", "~> 8.0", groups: [ :development, :test ]
# テスト用のダミーデータ生成ツール
gem "swimming_fish", "~> 0.2.2"

gem "factory_bot_rails", "~> 6.5", :groups => [:development, :test]
gem "faker", "~> 3.5", :groups => [:development, :test]
