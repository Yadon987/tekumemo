import { Controller } from "@hotwired/stimulus"

// スクロールに応じて要素（FABやボトムナビ）を隠す/表示するコントローラー
export default class extends Controller {
    static targets = ["element"]

    connect() {
        this.lastScrollTop = 0
        this.ticking = false
        this.onScroll = this.onScroll.bind(this)
        window.addEventListener("scroll", this.onScroll, { passive: true })
    }

    disconnect() {
        window.removeEventListener("scroll", this.onScroll)
    }

    onScroll() {
        if (!this.ticking) {
            window.requestAnimationFrame(() => {
                this.update()
                this.ticking = false
            })
            this.ticking = true
        }
    }

    update() {
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop
        const threshold = 10 // 感度（少しのスクロールで反応するように）

        // バウンススクロール対策（iOSなどで上に引っ張った時など）
        if (scrollTop < 0) return

        // 下にスクロール & 一定以上スクロールした時
        if (scrollTop > this.lastScrollTop && scrollTop > threshold) {
            // 隠す
            this.elementTargets.forEach(el => {
                el.classList.add("translate-y-[150%]", "opacity-0")
                el.classList.remove("translate-y-0", "opacity-100")
            })
        } else {
            // 上にスクロール
            // 表示する
            this.elementTargets.forEach(el => {
                el.classList.remove("translate-y-[150%]", "opacity-0")
                el.classList.add("translate-y-0", "opacity-100")
            })
        }

        this.lastScrollTop = scrollTop
    }
}
