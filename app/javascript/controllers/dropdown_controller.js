import { Controller } from "@hotwired/stimulus"

// ドロップダウンメニューの開閉を制御するコントローラー
export default class extends Controller {
    static targets = ["menu", "button"]

    connect() {
        // メニュー外クリックを検知するためのイベントリスナーを登録
        this.clickOutside = this.clickOutside.bind(this)
        document.addEventListener("click", this.clickOutside)
    }

    disconnect() {
        // コントローラー破棄時にイベントリスナーを削除
        document.removeEventListener("click", this.clickOutside)
    }

    // メニューの表示/非表示を切り替える
    toggle() {
        this.menuTarget.classList.toggle("hidden")

        // アニメーション用のクラスを切り替え（フェードイン・アウト用）
        if (this.menuTarget.classList.contains("hidden")) {
            this.menuTarget.classList.remove("opacity-100", "scale-100")
            this.menuTarget.classList.add("opacity-0", "scale-95")
        } else {
            // 表示時は少し遅延させてアニメーションクラスを適用（display: noneからの復帰用）
            requestAnimationFrame(() => {
                this.menuTarget.classList.remove("opacity-0", "scale-95")
                this.menuTarget.classList.add("opacity-100", "scale-100")
            })
        }
    }

    // メニューを閉じる
    close() {
        this.menuTarget.classList.add("hidden")
        this.menuTarget.classList.remove("opacity-100", "scale-100")
        this.menuTarget.classList.add("opacity-0", "scale-95")
    }

    // メニュー外をクリックした時に閉じる
    clickOutside(event) {
        if (!this.element.contains(event.target) && !this.menuTarget.classList.contains("hidden")) {
            this.close()
        }
    }
}
