import { Controller } from "@hotwired/stimulus";

// ボトムナビ向けコーチマークコントローラー
export default class extends Controller {
  // ステップ定義
  steps = [
    {
      targetId: "nav-home",
      title: "ホーム 🏠",
      message: "ここがあなたの出発点！\n今日の運動量や最新情報を確認できます。",
    },
    {
      targetId: "nav-walk",
      title: "散歩 👣",
      message: "今日の散歩を振り返ったり、\n過去の記録を確認できます。",
    },
    {
      targetId: "nav-post",
      title: "投稿 💬",
      message: "今日の気分や散歩の様子を\nシェアして仲間と繋がろう！",
    },
    {
      targetId: "nav-stats",
      title: "記録 📊",
      message: "グラフや統計で、あなたの成長を\n視覚的にチェックできます。",
    },
    {
      targetId: "nav-rank",
      title: "ランキング 🏆",
      message: "全国のユーザーと歩数を競おう！\n上位入賞で特別なバッジも…？",
    },
  ];

  connect() {
    // 既に見たかチェック（キーはcoachMarkV1とする）
    const hasSeen = localStorage.getItem("hasSeenCoachMarkV1");

    if (!hasSeen) {
      setTimeout(() => {
        this.start();
      }, 1000); // 1秒後に開始
    }
  }

  start() {
    this.currentStepIndex = 0;
    this.showOverlay();
    this.showStep(0);
  }

  showOverlay() {
    if (!this.overlay) {
      this.overlay = document.createElement("div");
      this.overlay.className =
        "fixed inset-0 bg-black/70 z-[9998] transition-opacity duration-300 opacity-0";
      document.body.appendChild(this.overlay);

      // フェードイン
      setTimeout(() => {
        this.overlay.classList.remove("opacity-0");
      }, 10);
    }
  }

  showStep(index) {
    const step = this.steps[index];
    if (!step) {
      this.complete();
      return;
    }

    const target = document.getElementById(step.targetId);
    if (!target) {
      // ターゲットが見つからない場合はスキップ
      this.showStep(index + 1);
      return;
    }

    // ハイライト処理
    this.highlightElement(target);

    // ツールチップ表示
    this.showTooltip(target, step);
  }

  highlightElement(element) {
    // 前のハイライトを解除
    if (this.currentHighlight) {
      this.currentHighlight.style.zIndex = "";
      this.currentHighlight.style.position = "";
      this.currentHighlight.classList.remove("relative");
    }

    // 今回の要素をハイライト
    element.style.position = "relative";
    element.style.zIndex = "9999"; // ツールチップ(10000)より下、オーバーレイ(9998)より上
    this.currentHighlight = element;

    // スポットライト効果（光る枠線）
    if (!this.spotlight) {
      this.spotlight = document.createElement("div");
      this.spotlight.className =
        "fixed pointer-events-none z-[9999] transition-all duration-300 rounded-full border-4 border-white/50 shadow-[0_0_30px_rgba(255,255,255,0.5)] animate-pulse";
      document.body.appendChild(this.spotlight);
    }

    const rect = element.getBoundingClientRect();
    // 少し大きめに枠を表示
    this.spotlight.style.top = `${rect.top - 5}px`;
    this.spotlight.style.left = `${rect.left - 5}px`;
    this.spotlight.style.width = `${rect.width + 10}px`;
    this.spotlight.style.height = `${rect.height + 10}px`;
  }

  showTooltip(target, step) {
    if (this.tooltip) {
      this.tooltip.remove();
    }

    this.tooltip = document.createElement("div");
    this.tooltip.className =
      "fixed z-[10000] w-64 max-w-[90vw] transition-all duration-300 opacity-0 transform translate-y-4";

    const isLast = this.currentStepIndex >= this.steps.length - 1;

    this.tooltip.innerHTML = `
      <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-xl p-4 border border-gray-100 dark:border-slate-700 relative">
        <!-- 吹き出しの三角（下向き） -->
        <div class="absolute -bottom-2 left-1/2 transform -translate-x-1/2 w-4 h-4 bg-white dark:bg-slate-800 rotate-45 border-b border-r border-gray-100 dark:border-slate-700"></div>

        <h3 class="font-bold text-lg text-gray-800 dark:text-white mb-2">${
          step.title
        }</h3>
        <p class="text-sm text-gray-600 dark:text-slate-300 mb-4 whitespace-pre-wrap leading-relaxed">${
          step.message
        }</p>

        <div class="flex justify-between items-center">
          <div class="flex space-x-1">
            ${this.steps
              .map(
                (_, i) => `
              <div class="w-1.5 h-1.5 rounded-full ${
                i === this.currentStepIndex
                  ? "bg-blue-500"
                  : "bg-gray-200 dark:bg-slate-600"
              }"></div>
            `
              )
              .join("")}
          </div>

          <div class="flex gap-2">
            <button id="coach-skip-btn" class="text-xs text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 px-2">スキップ</button>
            <button id="coach-next-btn" class="text-xs bg-blue-500 hover:bg-blue-600 text-white font-bold py-1.5 px-4 rounded-full transition-colors shadow-md">
              ${isLast ? "完了！" : "次へ"}
            </button>
          </div>
        </div>
      </div>
    `;

    document.body.appendChild(this.tooltip);

    // イベントリスナー
    document
      .getElementById("coach-skip-btn")
      .addEventListener("click", () => this.complete());
    document.getElementById("coach-next-btn").addEventListener("click", () => {
      this.currentStepIndex++;
      this.showStep(this.currentStepIndex);
    });

    // 位置計算（ターゲットの上に表示）
    const rect = target.getBoundingClientRect();
    const tooltipRect = this.tooltip.getBoundingClientRect(); // まだDOMに追加した直後でサイズが取れないかも？

    // 一度表示してサイズを取得
    this.tooltip.style.visibility = "hidden";
    this.tooltip.style.display = "block";
    const finalRect = this.tooltip.getBoundingClientRect();
    this.tooltip.style.visibility = "visible";

    // 画面中央に寄せるためのオフセット
    const left = Math.max(
      10,
      Math.min(
        window.innerWidth - finalRect.width - 10,
        rect.left + rect.width / 2 - finalRect.width / 2
      )
    );
    const top = rect.top - finalRect.height - 20; // 20px上に

    this.tooltip.style.left = `${left}px`;
    this.tooltip.style.top = `${top}px`;

    // アニメーション
    requestAnimationFrame(() => {
      this.tooltip.classList.remove("opacity-0", "translate-y-4");
    });
  }

  complete() {
    // 片付け
    if (this.overlay) this.overlay.remove();
    if (this.tooltip) this.tooltip.remove();
    if (this.spotlight) this.spotlight.remove();

    if (this.currentHighlight) {
      this.currentHighlight.style.zIndex = "";
      this.currentHighlight.style.position = "";
    }

    // 記録
    localStorage.setItem("hasSeenCoachMarkV1", "true");
  }
}
