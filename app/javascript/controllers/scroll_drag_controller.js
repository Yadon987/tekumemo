import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.isDown = false
    this.startX = 0
    this.scrollLeft = 0

    // イベントリスナーのバインド（thisを固定）
    this.startHandler = this.start.bind(this)
    this.stopHandler = this.stop.bind(this)
    this.moveHandler = this.move.bind(this)

    // マウスイベント
    this.element.addEventListener('mousedown', this.startHandler)
    this.element.addEventListener('mouseleave', this.stopHandler)
    this.element.addEventListener('mouseup', this.stopHandler)
    this.element.addEventListener('mousemove', this.moveHandler)

    // タッチイベント
    this.element.addEventListener('touchstart', this.startHandler, { passive: true })
    this.element.addEventListener('touchend', this.stopHandler)
    this.element.addEventListener('touchmove', this.moveHandler, { passive: false })

    this.element.classList.add('cursor-grab')
    this.element.classList.remove('cursor-grabbing')
  }

  disconnect() {
    // イベントリスナーの削除
    this.element.removeEventListener('mousedown', this.startHandler)
    this.element.removeEventListener('mouseleave', this.stopHandler)
    this.element.removeEventListener('mouseup', this.stopHandler)
    this.element.removeEventListener('mousemove', this.moveHandler)

    this.element.removeEventListener('touchstart', this.startHandler)
    this.element.removeEventListener('touchend', this.stopHandler)
    this.element.removeEventListener('touchmove', this.moveHandler)
  }

  start(e) {
    this.isDown = true
    this.element.classList.add('cursor-grabbing')
    this.element.classList.remove('cursor-grab')
    this.element.classList.remove('snap-x', 'snap-mandatory')

    const pageX = e.pageX || (e.touches ? e.touches[0].pageX : 0)
    this.startX = pageX - this.element.offsetLeft
    this.scrollLeft = this.element.scrollLeft
  }

  stop() {
    if (!this.isDown) return
    this.isDown = false
    this.element.classList.remove('cursor-grabbing')
    this.element.classList.add('cursor-grab')

    setTimeout(() => {
      this.element.classList.add('snap-x', 'snap-mandatory')
    }, 100)
  }

  move(e) {
    if (!this.isDown) return

    // マウスの場合はデフォルト動作（テキスト選択など）を防ぐ
    if (!e.touches) {
      e.preventDefault()
    }

    const pageX = e.pageX || (e.touches ? e.touches[0].pageX : 0)
    const x = pageX - this.element.offsetLeft
    const walk = (x - this.startX) * 2 // スクロール速度
    this.element.scrollLeft = this.scrollLeft - walk
  }
}
