import { Controller } from "@hotwired/stimulus"

// モーダル制御用コントローラー
export default class extends Controller {
  static values = {
    dialogId: String,
    autoOpenParam: String // URLパラメータのキー（例: 'open_modal'）を指定
  }

  connect() {
    // ページ読み込み時に自動オープン設定があるかチェック
    if (this.hasAutoOpenParamValue) {
      this.checkAutoOpen()
    }
  }

  checkAutoOpen() {
    const urlParams = new URLSearchParams(window.location.search)
    if (urlParams.get(this.autoOpenParamValue) === 'true') {
      // 少し遅延させて実行しないと、アニメーションや他の初期化と競合する場合がある
      setTimeout(() => {
        // 自分自身がdialog要素の場合は直接開く、そうでなければIDで探す
        if (this.element.tagName === 'DIALOG') {
          this.openDialogElement(this.element)
        } else {
          this.open()
        }
      }, 100)
      
      this.cleanUrl()
    }
  }

  cleanUrl() {
    // URLからパラメータを削除
    const url = new URL(window.location)
    url.searchParams.delete(this.autoOpenParamValue)
    window.history.replaceState({}, '', url)
  }

  open() {
    const dialog = document.getElementById(this.dialogIdValue)
    if (dialog) {
      this.openDialogElement(dialog)
    }
  }

  openDialogElement(dialog) {
    dialog.showModal()
    document.body.classList.add('overflow-hidden')

    // ダイアログ外クリックで閉じるイベントを登録
    dialog.addEventListener('click', (e) => {
      if (e.target === dialog) {
        this.closeDialog(dialog)
      }
    }, { once: true })
  }

  close() {
    // コントローラーがアタッチされている要素の親のdialogを探す
    const dialog = this.element.closest('dialog')
    if (dialog) {
      this.closeDialog(dialog)
    }
  }

  closeDialog(dialog) {
    dialog.close()
    document.body.classList.remove('overflow-hidden')
  }
}
