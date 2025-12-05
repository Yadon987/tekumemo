import { Controller } from "@hotwired/stimulus"

// FAB (Floating Action Button) の展開/折りたたみを制御
export default class extends Controller {
  static targets = ["menu", "icon"]

  connect() {
    this.isOpen = false
  }

  toggle() {
    this.isOpen = !this.isOpen

    if (this.isOpen) {
      // メニューを展開
      this.menuTarget.classList.remove("opacity-0", "scale-0")
      this.menuTarget.classList.add("opacity-100", "scale-100")

      // アイコンを回転
      this.iconTarget.style.transform = "rotate(45deg)"
    } else {
      // メニューを折りたたむ
      this.menuTarget.classList.remove("opacity-100", "scale-100")
      this.menuTarget.classList.add("opacity-0", "scale-0")

      // アイコンを元に戻す
      this.iconTarget.style.transform = "rotate(0deg)"
    }
  }
}
