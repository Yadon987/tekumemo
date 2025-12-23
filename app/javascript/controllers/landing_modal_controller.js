import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal", "content", "count"]

  connect() {
    // モーダル初期化（非表示）
    this.close()
  }

  open(event) {
    event.preventDefault()

    // クリックされた要素から機能タイプを取得
    const featureType = event.currentTarget.dataset.featureType

    // すべてのコンテンツを非表示にし、該当するものだけ表示
    this.contentTargets.forEach(target => {
      if (target.dataset.featureType === featureType) {
        target.classList.remove("hidden")

        // アニメーションをリセットするために要素を再描画させるハック
        // クラスを一度削除して再付与することで、確実にアニメーションを再開させる
        const animationClasses = ['animate-dash', 'animate-grow-h-12', 'animate-grow-h-16', 'animate-grow-h-24', 'animate-shimmer', 'animate-pop-in', 'animate-float-up']

        // 対象となる要素をすべて取得
        const animatedElements = target.querySelectorAll(animationClasses.map(c => `.${c}`).join(', '))

        animatedElements.forEach(el => {
          // その要素が持っているアニメーションクラスを特定
          const activeClass = animationClasses.find(c => el.classList.contains(c))

          if (activeClass) {
            el.classList.remove(activeClass)
            void el.offsetWidth // trigger reflow
            el.classList.add(activeClass)
          }
        })

        // カウントアップ演出の実行
        const countElements = target.querySelectorAll('[data-landing-modal-target="count"]')
        countElements.forEach(el => {
          const endValue = parseInt(el.dataset.countTo, 10)
          this.animateValue(el, 0, endValue, 1500)
        })

      } else {
        target.classList.add("hidden")
      }
    })

    // モーダルを表示
    this.modalTarget.classList.remove("hidden")
    // アニメーション用クラスを追加（フェードイン）
    this.modalTarget.classList.add("animate-fade-in")

    // 背景スクロール固定
    document.body.style.overflow = "hidden"
  }

  close(event) {
    if (event) event.preventDefault()

    this.modalTarget.classList.add("hidden")
    this.modalTarget.classList.remove("animate-fade-in")

    // 背景スクロール解除
    document.body.style.overflow = "auto"
  }

  // 数値をカウントアップさせるヘルパーメソッド
  animateValue(obj, start, end, duration) {
    let startTimestamp = null;
    const step = (timestamp) => {
      if (!startTimestamp) startTimestamp = timestamp;
      const progress = Math.min((timestamp - startTimestamp) / duration, 1);

      // イージング関数（easeOutExpoっぽい動き）
      const easeProgress = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress);

      const current = Math.floor(easeProgress * (end - start) + start);
      obj.innerHTML = current.toLocaleString(); // カンマ区切り

      if (progress < 1) {
        window.requestAnimationFrame(step);
      }
    };
    window.requestAnimationFrame(step);
  }
}
