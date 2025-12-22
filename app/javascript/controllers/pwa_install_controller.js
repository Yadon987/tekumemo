import { Controller } from "@hotwired/stimulus";

// PWAインストールプロンプトを管理するコントローラー
export default class extends Controller {
  static targets = ["banner"];

  connect() {
    console.log("[PWA Install] Controller connected")

    // グローバルに保存されたイベントがあれば復元
    if (window.pwaInstallPrompt) {
      this.deferredPrompt = window.pwaInstallPrompt
    }

    // 既にインストール済みかチェック
    if (window.matchMedia('(display-mode: standalone)').matches) {
      console.log('[PWA Install] Already installed')
      return
    }

    console.log('[PWA Install] Waiting for beforeinstallprompt event...')

    // beforeinstallprompt イベントをキャプチャ
    window.addEventListener('beforeinstallprompt', (e) => {
      console.log('[PWA Install] beforeinstallprompt event fired!')

      // デフォルトのプロンプトを防ぐ
      e.preventDefault()

      // 後で使えるようにイベントを保存
      this.deferredPrompt = e
      window.pwaInstallPrompt = e // グローバルにも保存（設定画面などで使うため）

      // 以前に閉じていなければバナーを表示
      const dismissed = localStorage.getItem('pwa-install-dismissed')
      if (!dismissed) {
        this.showBanner()
      } else {
        console.log('[PWA Install] Banner suppressed because it was dismissed previously')
      }
    })

    // インストール完了時にバナーを非表示
    window.addEventListener('appinstalled', () => {
      this.hideBanner()
      window.pwaInstallPrompt = null
    })
  }

  // バナーを表示
  showBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.remove("hidden");
      // アニメーション用
      setTimeout(() => {
        this.bannerTarget.classList.add("translate-y-0", "opacity-100");
        this.bannerTarget.classList.remove("translate-y-4", "opacity-0");
      }, 100);
    }
  }

  // バナーを非表示
  hideBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.add("translate-y-4", "opacity-0");
      this.bannerTarget.classList.remove("translate-y-0", "opacity-100");
      setTimeout(() => {
        this.bannerTarget.classList.add("hidden");
      }, 300);
    }
  }

  // インストールボタンをクリック
  async install() {
    if (!this.deferredPrompt) {
      return;
    }

    // インストールプロンプトを表示
    this.deferredPrompt.prompt();

    // ユーザーの選択を待つ
    const { outcome } = await this.deferredPrompt.userChoice;

    console.log(`User response to the install prompt: ${outcome}`);

    // プロンプトを使い切ったのでクリア
    this.deferredPrompt = null;

    // バナーを非表示
    this.hideBanner();
  }

  // ×ボタンをクリック
  dismiss() {
    // ローカルストレージに記録（次回から表示しない）
    localStorage.setItem("pwa-install-dismissed", "true");

    // バナーを非表示
    this.hideBanner();
  }
}
