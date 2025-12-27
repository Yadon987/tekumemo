import { Controller } from "@hotwired/stimulus";

// 水平スクロールコンテナをマウスドラッグで操作できるようにするコントローラー
export default class extends Controller {
  connect() {
    this.isDown = false;
    this.startX = 0;
    this.scrollLeft = 0;

    // スタイル適用（掴めることを示す）
    this.element.style.cursor = "grab";
    this.element.classList.add("cursor-grab"); // Tailwind用

    // イベントリスナー登録
    this.element.addEventListener("mousedown", this.start.bind(this));
    this.element.addEventListener("mouseleave", this.stop.bind(this));
    this.element.addEventListener("mouseup", this.stop.bind(this));
    this.element.addEventListener("mousemove", this.move.bind(this));

    // タッチデバイスのアクション競合防止（必要に応じて）
    // this.element.style.touchAction = "pan-x"
  }

  start(e) {
    this.isDown = true;
    this.element.classList.add("cursor-grabbing");
    this.element.style.cursor = "grabbing";
    this.startX = e.pageX - this.element.offsetLeft;
    this.scrollLeft = this.element.scrollLeft;
  }

  stop() {
    this.isDown = false;
    this.element.classList.remove("cursor-grabbing");
    this.element.style.cursor = "grab";
  }

  move(e) {
    if (!this.isDown) return;
    e.preventDefault();
    const x = e.pageX - this.element.offsetLeft;
    const walk = (x - this.startX) * 1.5; // スクロール速度倍率
    this.element.scrollLeft = this.scrollLeft - walk;
  }
}
