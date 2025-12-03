// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// Entry point for the build script in your package.json
import "@hotwired/turbo-rails";
import "controllers";

// モーダルトリガーの設定（Turbo対応）
document.addEventListener("turbo:load", () => {
  document.querySelectorAll("[data-modal-trigger]").forEach((trigger) => {
    trigger.addEventListener("click", () => {
      const modalId = trigger.dataset.modalTrigger;
      const modal = document.getElementById(modalId);
      if (modal) {
        modal.showModal();
      }
    });
  });
});
// ダークモード機能はStimulusコントローラー（dark_mode_toggle_controller.js）で実装
// Google Fit連携はStimulusコントローラー（google_fit_controller.js）で実装
