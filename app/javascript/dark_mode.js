// =====================================
// ダークモード機能
// =====================================
// このファイルでは、ダークモード（暗いテーマ）とライトモード（明るいテーマ）を
// 切り替える機能を実装しています

// -------------------------------------
// 関数1: ダークモードの状態を読み込む
// -------------------------------------
// ページを表示する前に、以前の設定を読み込んでダークモードを適用します
// これにより、ページが表示されるときにチラつくのを防ぎます
function initializeDarkMode() {
  // localStorageから前回の設定を取得（なければ'light'を使用）
  const theme = localStorage.getItem('theme') || 'light';

  // 取得した設定がdark（ダークモード）の場合
  if (theme === 'dark') {
    // htmlタグにdarkクラスを追加（これでダークモード用のスタイルが適用される）
    document.documentElement.classList.add('dark');
  } else {
    // それ以外の場合はdarkクラスを削除（ライトモードにする）
    document.documentElement.classList.remove('dark');
  }
}

// -------------------------------------
// 関数2: ボタンクリック時の処理（名前付き関数）
// -------------------------------------
// この関数を名前付きにすることで、後で削除や再登録ができます
function toggleDarkMode() {
  // htmlタグを取得（ここにdarkクラスを追加/削除する）
  const html = document.documentElement;

  // 現在ダークモードかどうかを確認
  const isDark = html.classList.contains('dark');

  // 現在の状態に応じて切り替える
  if (isDark) {
    // 今がダークモードなら→ライトモードに切り替え
    html.classList.remove('dark'); // darkクラスを削除
    localStorage.setItem('theme', 'light'); // 設定を保存
  } else {
    // 今がライトモードなら→ダークモードに切り替え
    html.classList.add('dark'); // darkクラスを追加
    localStorage.setItem('theme', 'dark'); // 設定を保存
  }
}

// -------------------------------------
// 関数3: ダークモード切り替えボタンの設定
// -------------------------------------
// ボタンをクリックしたときの動作を設定します
function setupDarkModeToggle() {
  // id="darkModeToggle"のボタンを取得
  const darkModeToggle = document.getElementById('darkModeToggle');

  // ボタンが見つかった場合のみ処理を実行
  if (!darkModeToggle) {
    return; // ボタンがなければここで終了
  }

  // 既存のイベントリスナーを削除（重複登録を防ぐため）
  // ※Turboでページ遷移するたびにこの関数が呼ばれるので、
  //   古いイベントリスナーを削除してから新しいのを登録します
  darkModeToggle.removeEventListener('click', toggleDarkMode);

  // 新しくイベントリスナーを登録
  darkModeToggle.addEventListener('click', toggleDarkMode);
}

// -------------------------------------
// 実行部分：イベントの設定
// -------------------------------------

// スクリプトが読み込まれたら即座にダークモードを初期化
// （これがないと、ページ表示時にチラつく可能性がある）
initializeDarkMode();

// Turbo（ページ遷移を高速化する仕組み）のページロード時に実行
document.addEventListener('turbo:load', function() {
  initializeDarkMode(); // ダークモードの状態を再適用
  setupDarkModeToggle(); // ボタンのクリックイベントを設定
});

// 通常のページロード時にも実行（Turboが無効な場合のため）
document.addEventListener('DOMContentLoaded', function() {
  setupDarkModeToggle(); // ボタンのクリックイベントを設定
});

// Turboでページ遷移する直前にもダークモードを再適用
// （遷移先でも同じテーマが維持されるようにする）
document.addEventListener('turbo:before-render', function() {
  initializeDarkMode(); // ダークモードの状態を再適用
});
