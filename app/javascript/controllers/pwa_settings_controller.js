import { Controller } from "@hotwired/stimulus"

// 設定画面のPWAインストールボタンを管理するコントローラー
export default class extends Controller {
  static targets = ["installButton", "iosGuideModal"]

  connect() {
    console.log("[PWA Settings] Controller connected")

    // 既にインストール済み（スタンドアローンモード）の場合はボタンを非表示
    if (window.matchMedia('(display-mode: standalone)').matches) {
      console.log("[PWA Settings] Running in standalone mode. Removing install button.")
      if (this.hasInstallButtonTarget) {
        this.installButtonTarget.remove()
      }
      return
    }

    console.log("[PWA Settings] Not in standalone mode. Button should be visible.")

    // iOSかどうか判定
    this.isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream
    console.log(`[PWA Settings] isIOS: ${this.isIOS}`)
  }

  // インストールボタンクリック時の処理
  install() {
    if (this.isIOS) {
      // iOSの場合はガイドを表示
      this.showIOSGuide()
    } else {
      // Android/PCの場合はプロンプトを表示
      this.promptInstall()
    }
  }

  // Android/PC向けのインストールプロンプト表示
  async promptInstall() {
    const promptEvent = window.pwaInstallPrompt

    if (!promptEvent) {
      // イベントがない場合（Chromeで一度拒否した後など）
      alert('ブラウザのメニューから「アプリをインストール」を選択してください。')
      return
    }

    // プロンプトを表示
    promptEvent.prompt()

    // ユーザーの選択を待つ
    const { outcome } = await promptEvent.userChoice
    console.log(`User response to the install prompt: ${outcome}`)

    // プロンプトは一度しか使えないのでクリア
    window.pwaInstallPrompt = null

    // インストールされたらボタンを消す（appinstalledイベントでも良いが念のため）
    if (outcome === 'accepted') {
      this.installButtonTarget.remove()
    }
  }

  // iOS向けのガイドモーダル表示
  showIOSGuide() {
    if (this.hasIosGuideModalTarget) {
      this.iosGuideModalTarget.classList.remove('hidden')
      // アニメーション
      setTimeout(() => {
        this.iosGuideModalTarget.querySelector('.modal-content').classList.remove('scale-95', 'opacity-0')
        this.iosGuideModalTarget.querySelector('.modal-content').classList.add('scale-100', 'opacity-100')
      }, 10)
    } else {
      alert('Safariの「共有」ボタンから「ホーム画面に追加」を選択してください。')
    }
  }

  // iOSガイドを閉じる
  closeIOSGuide() {
    if (this.hasIosGuideModalTarget) {
      this.iosGuideModalTarget.querySelector('.modal-content').classList.add('scale-95', 'opacity-0')
      this.iosGuideModalTarget.querySelector('.modal-content').classList.remove('scale-100', 'opacity-100')
      setTimeout(() => {
        this.iosGuideModalTarget.classList.add('hidden')
      }, 200)
    }
  }
}
