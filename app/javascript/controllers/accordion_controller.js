import { Controller } from "@hotwired/stimulus";

// シンプルなアコーディオン（開閉）コントローラー
export default class extends Controller {
  static targets = ["content", "icon"];
  static values = { isOpen: Boolean };

  connect() {
    // 初期状態の適用
    this.updateState();
  }

  toggle() {
    this.isOpenValue = !this.isOpenValue;
    this.updateState();
  }

  updateState() {
    if (this.isOpenValue) {
      this.contentTarget.classList.remove("hidden");
      this.iconTarget.style.transform = "rotate(180deg)";
    } else {
      this.contentTarget.classList.add("hidden");
      this.iconTarget.style.transform = "rotate(0deg)";
    }
  }
}
