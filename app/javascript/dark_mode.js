// ダークモード機能
// ページ読み込み前にダークモードを設定（FOUC防止）
function initializeDarkMode() {
  const theme = localStorage.getItem('theme') || 'light';
  if (theme === 'dark') {
    document.documentElement.classList.add('dark');
  } else {
    document.documentElement.classList.remove('dark');
  }
}

// ダークモード切り替えボタンのイベントリスナーを設定
function setupDarkModeToggle() {
  const darkModeToggle = document.getElementById('darkModeToggle');

  if (darkModeToggle) {
    // 既存のイベントリスナーを削除（重複登録を防ぐ）
    const newToggle = darkModeToggle.cloneNode(true);
    darkModeToggle.parentNode.replaceChild(newToggle, darkModeToggle);

    newToggle.addEventListener('click', function() {
      const html = document.documentElement;
      const isDark = html.classList.contains('dark');

      if (isDark) {
        // ライトモードに切り替え
        html.classList.remove('dark');
        localStorage.setItem('theme', 'light');
      } else {
        // ダークモードに切り替え
        html.classList.add('dark');
        localStorage.setItem('theme', 'dark');
      }
    });
  }
}

// 初期化処理（スクリプト読み込み時に即座に実行）
initializeDarkMode();

// Turboのページロードイベントでダークモードを再初期化
document.addEventListener('turbo:load', function() {
  initializeDarkMode();
  setupDarkModeToggle();
});

// 通常のDOMContentLoadedイベント（Turboが無効な場合のフォールバック）
document.addEventListener('DOMContentLoaded', function() {
  setupDarkModeToggle();
});

// Turbo遷移前にダークモードの状態を保持
document.addEventListener('turbo:before-render', function() {
  initializeDarkMode();
});
