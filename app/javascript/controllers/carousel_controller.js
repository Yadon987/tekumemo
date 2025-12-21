import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container", "indicator"]
    static values = {
        interval: { type: Number, default: 5000 },
        enable: { type: Boolean, default: true }
    }

    connect() {
        this.isDragging = false
        this.startX = 0
        this.scrollLeft = 0
        this.currentIndex = 0

        // スライドの枚数を取得（インジケーターの数から推測）
        this.slideCount = this.indicatorTargets.length

        // イベントリスナーの登録
        // タッチイベント
        this.containerTarget.addEventListener('touchstart', this.touchStart.bind(this), { passive: true })
        this.containerTarget.addEventListener('touchmove', this.touchMove.bind(this), { passive: true })
        this.containerTarget.addEventListener('touchend', this.touchEnd.bind(this))

        // マウスイベント
        this.containerTarget.addEventListener('mousedown', this.touchStart.bind(this))
        this.containerTarget.addEventListener('mouseup', this.touchEnd.bind(this))
        this.containerTarget.addEventListener('mouseleave', () => {
            if (this.isDragging) this.touchEnd()
        })
        this.containerTarget.addEventListener('mousemove', this.touchMove.bind(this))

        // コンテキストメニュー無効化（右クリックドラッグ防止）
        this.containerTarget.oncontextmenu = function (event) {
            event.preventDefault()
            event.stopPropagation()
            return false
        }

        this.startAutoPlay()
    }

    disconnect() {
        this.stopAutoPlay()
    }

    // --- イベントハンドラ ---

    touchStart(event) {
        this.stopAutoPlay()
        this.isDragging = true
        this.startX = this.getPositionX(event)
        this.scrollLeft = this.containerTarget.scrollLeft

        this.containerTarget.classList.add('cursor-grabbing')
        this.containerTarget.classList.remove('cursor-grab')
    }

    touchMove(event) {
        if (!this.isDragging) return

        // マウスの場合はデフォルト動作（テキスト選択など）を防ぐ
        if (event.type.includes('mouse')) {
            event.preventDefault()
        }

        const x = this.getPositionX(event)
        const walk = (x - this.startX) * 1.5 // 1.5倍速で追従
        this.containerTarget.scrollLeft = this.scrollLeft - walk
    }

    touchEnd() {
        if (!this.isDragging) return
        this.isDragging = false

        this.containerTarget.classList.remove('cursor-grabbing')
        this.containerTarget.classList.add('cursor-grab')

        // スナップ処理
        this.snapToNearestSlide()
        this.startAutoPlay()
    }

    // --- ヘルパーメソッド ---

    getPositionX(event) {
        return event.type.includes('mouse') ? event.pageX : event.touches[0].clientX
    }

    snapToNearestSlide() {
        const slideWidth = this.containerTarget.offsetWidth // コンテナ幅をスライド幅とみなす（1枚表示の場合）
        const scrollLeft = this.containerTarget.scrollLeft

        // 現在のスクロール位置から最も近いスライドのインデックスを計算
        let newIndex = Math.round(scrollLeft / slideWidth)

        // 範囲制限
        if (newIndex < 0) newIndex = 0
        if (newIndex >= this.slideCount) newIndex = this.slideCount - 1

        this.currentIndex = newIndex
        this.scrollToSlide()
    }

    scrollToSlide() {
        const slideWidth = this.containerTarget.offsetWidth
        // ギャップ（gap-4 = 16px）を考慮するかどうかだが、snap-centerを使わない場合は
        // コンテナ幅 * インデックス で概ね合うはず（width: 100% の場合）
        // ただし、gapがある場合は少しずれる可能性がある。
        // 今回は min-w-full なので、コンテナ幅 = スライド幅。
        // gap-4 があるので、2枚目以降は gap 分ずれる。

        // 正確には、各スライドの offsetLeft を取得するのがベスト
        // しかし slideTargets が定義されていない（HTML側で data-carousel-target="slide" があるはずだが）
        // ここでは簡易的に offsetWidth を使うが、より正確にするなら slideTargets を使うべき。

        // slideTargets を取得してみる（connectで取得していないので、DOMから直接）
        const slides = Array.from(this.containerTarget.children)
        if (slides[this.currentIndex]) {
            const slide = slides[this.currentIndex]
            this.containerTarget.scrollTo({
                left: slide.offsetLeft,
                behavior: 'smooth'
            })
        }

        this.updateIndicators()
    }

    // --- 自動再生 ---

    startAutoPlay() {
        if (!this.enableValue) return
        this.stopAutoPlay()
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
        this.currentIndex = (this.currentIndex + 1) % this.slideCount
        this.scrollToSlide()
    }

    updateIndicators() {
        this.indicatorTargets.forEach((indicator, index) => {
            if (index === this.currentIndex) {
                indicator.classList.add("bg-white", "w-6")
                indicator.classList.remove("bg-white/40", "w-2")
            } else {
                indicator.classList.add("bg-white/40", "w-2")
                indicator.classList.remove("bg-white", "w-6")
            }
        })
    }
}
