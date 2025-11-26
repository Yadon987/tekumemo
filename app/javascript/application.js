// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
// ダークモード機能はStimulusコントローラー（dark_mode_toggle_controller.js）で実装
// Google Fit連携はStimulusコントローラー（google_fit_controller.js）で実装
