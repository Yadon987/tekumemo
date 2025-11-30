import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container", "slide", "indicator"]
    static values = {
        interval: { type: Number, default: 5000 }, // 自動切り替え間隔（ミリ秒）
        enable: { type: Boolean, default: true }   // カルーセルを有効にするかどうか
    }

    connect() {
        // PCサイズ（sm以上）ではカルーセルを無効化するロジックが必要ならここに追加
        // 今回はCSS（Tailwind）でレイアウトを切り替えるため、JSは常に動いていても問題ないが、
        // パフォーマンスのために画面幅チェックを入れても良い。
        // ここではシンプルに常に動作させ、CSSで表示を制御するアプローチをとる。

        this.currentIndex = 0
        this.startAutoPlay()

        // タッチ操作やマウスホバーで自動再生を一時停止
        this.containerTarget.addEventListener("touchstart", () => this.stopAutoPlay(), { passive: true })
        this.containerTarget.addEventListener("mouseenter", () => this.stopAutoPlay())
        this.containerTarget.addEventListener("touchend", () => this.startAutoPlay())
        this.containerTarget.addEventListener("mouseleave", () => this.startAutoPlay())

        // スクロールイベントを監視してインジケーターを更新
        this.containerTarget.addEventListener("scroll", () => this.onScroll(), { passive: true })
    }

    onScroll() {
        const scrollLeft = this.containerTarget.scrollLeft
        const slideWidth = this.slideTargets[0].offsetWidth
        // 中心に近いスライドのインデックスを計算
        const index = Math.round(scrollLeft / slideWidth)

        if (this.currentIndex !== index && index < this.slideTargets.length) {
            this.currentIndex = index
            this.updateIndicators()
        }
    }

    disconnect() {
        this.stopAutoPlay()
    }

    startAutoPlay() {
        if (!this.enableValue) return
        this.stopAutoPlay() // 多重起動防止
        this.timer = setInterval(() => {
            this.next()
        }, this.intervalValue)
    }

    stopAutoPlay() {
        if (this.timer) {
            clearInterval(this.timer)
            this.timer = null
        }
    }

    next() {
        if (this.slideTargets.length === 0) return
        this.currentIndex = (this.currentIndex + 1) % this.slideTargets.length
        this.scrollToSlide()
    }

    scrollToSlide() {
        const slide = this.slideTargets[this.currentIndex]

        // スムーズスクロールで移動
        this.containerTarget.scrollTo({
            left: slide.offsetLeft,
            behavior: 'smooth'
        })

        this.updateIndicators()
    }

    updateIndicators() {
        this.indicatorTargets.forEach((indicator, index) => {
            if (index === this.currentIndex) {
                indicator.classList.add("bg-blue-500", "w-6")
                indicator.classList.remove("bg-gray-300", "w-2")
            } else {
                indicator.classList.add("bg-gray-300", "w-2")
                indicator.classList.remove("bg-blue-500", "w-6")
            }
        })
    }
}
