import { Controller } from "@hotwired/stimulus"

// モーダル制御用コントローラー
export default class extends Controller {
  static values = { dialogId: String }

  open() {
    const dialog = document.getElementById(this.dialogIdValue)
    if (dialog) {
      dialog.showModal()
      document.body.classList.add('overflow-hidden')

      // ダイアログ外クリックで閉じるイベントを登録
      dialog.addEventListener('click', (e) => {
        if (e.target === dialog) {
          this.closeDialog(dialog)
        }
      }, { once: true }) // 重複登録防止
    }
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
