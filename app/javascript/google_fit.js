// Google Fitからデータを取得してフォームに自動入力する機能
// 散歩記録作成・編集フォームで使用

// Google Fitデータ取得処理を実行する関数
function setupGoogleFitButton() {
  // Google Fitデータ取得ボタンを取得
  const fetchButton = document.getElementById('fetchGoogleFitData');
  if (!fetchButton) {
    console.log('Google Fit button not found');
    return;
  }

  console.log('Google Fit button found, setting up event listener');

  // 既存のイベントリスナーを削除（重複防止）
  fetchButton.replaceWith(fetchButton.cloneNode(true));
  const newButton = document.getElementById('fetchGoogleFitData');

  // ボタンクリック時の処理
  newButton.addEventListener('click', async () => {
    console.log('Google Fit button clicked');
    // 選択された日付を取得
    const dateField = document.getElementById('walk_walked_on');
    const selectedDate = dateField ? dateField.value : null;

    console.log('Selected date:', selectedDate);

    if (!selectedDate) {
      alert('散歩日を選択してください');
      return;
    }

    // ボタンを無効化してローディング状態にする
    newButton.disabled = true;
    newButton.classList.add('opacity-50', 'cursor-not-allowed');
    newButton.innerHTML = `
      <svg class="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      <span>取得中...</span>
    `;

    try {
      // Google Fit APIからデータを取得
      const response = await fetch(`/google_fit/daily_data?date=${selectedDate}`, {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      });

      if (!response.ok) {
        throw new Error('データの取得に失敗しました');
      }

      const data = await response.json();

      // エラーチェック
      if (data.error) {
        alert(data.error);
        return;
      }

      // 取得したデータをフォームに入力
      const distanceField = document.getElementById('walk_distance');
      const durationField = document.getElementById('walk_duration');
      const stepsField = document.getElementById('walk_steps');
      const caloriesField = document.getElementById('walk_calories_burned');

      // 距離をフォームに入力
      if (distanceField && data.distance !== undefined) {
        distanceField.value = data.distance;
      }

      // 時間をフォームに入力
      if (durationField && data.duration !== undefined) {
        durationField.value = data.duration;
      }

      // 歩数をフォームに入力
      if (stepsField && data.steps !== undefined) {
        stepsField.value = data.steps;
      }

      // 消費カロリーをフォームに入力
      if (caloriesField && data.calories !== undefined) {
        caloriesField.value = data.calories;
      }

      // ステータス表示を更新
      const statusElement = document.getElementById('googleFitStatus');
      if (statusElement) {
        statusElement.textContent = `取得完了: ${data.steps || 0}歩、${data.calories || 0}kcal`;
        statusElement.classList.add('text-green-600', 'dark:text-green-400');
      }

      // 成功メッセージを表示
      const message = document.createElement('div');
      message.className = 'bg-green-100 dark:bg-green-900/30 border border-green-400 dark:border-green-600 text-green-700 dark:text-green-300 px-4 py-3 rounded-lg mt-4';
      message.innerHTML = `
        <div class="flex items-center space-x-2">
          <span class="material-symbols-outlined">check_circle</span>
          <span>Google Fitからデータを取得しました</span>
        </div>
        <div class="mt-2 text-sm">
          <p>歩数: ${data.steps || 0}歩 | 距離: ${data.distance || 0}km</p>
          <p>時間: ${data.duration || 0}分 | カロリー: ${data.calories || 0}kcal</p>
        </div>
      `;

      // メッセージを表示（既存のメッセージがあれば削除）
      const existingMessage = document.querySelector('.google-fit-message');
      if (existingMessage) {
        existingMessage.remove();
      }

      message.classList.add('google-fit-message');
      newButton.parentElement.appendChild(message);

      // 5秒後にメッセージを削除
      setTimeout(() => {
        message.remove();
      }, 5000);

    } catch (error) {
      console.error('Google Fit data fetch error:', error);
      alert('データの取得に失敗しました。もう一度お試しください。');
    } finally {
      // ボタンを元の状態に戻す
      newButton.disabled = false;
      newButton.classList.remove('opacity-50', 'cursor-not-allowed');
      newButton.innerHTML = `
        <span class="material-symbols-outlined">download</span>
        <span>今日のデータを取得</span>
      `;
    }
  });
}

// Turboイベントとページロード時の両方で実行
document.addEventListener('turbo:load', setupGoogleFitButton);
document.addEventListener('DOMContentLoaded', setupGoogleFitButton);

// 初回ロード時にも実行
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', setupGoogleFitButton);
} else {
  setupGoogleFitButton();
}
