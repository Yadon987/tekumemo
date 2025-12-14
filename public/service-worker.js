// プッシュ通知イベントのリスナー
self.addEventListener("push", function (event) {
  let title = "てくメモ";
  let options = {
    body: "新しい通知があります",
    icon: "/icon-192.png", // アプリアイコン（後で用意する必要あり）
    badge: "/icon-192.png", // Androidのステータスバー用アイコン
    data: {
      url: "/", // 通知クリック時の遷移先
    },
  };

  if (event.data) {
    const data = event.data.json();
    title = data.title || title;
    options.body = data.body || options.body;
    options.icon = data.icon || options.icon;
    options.data.url = data.url || options.data.url;

    // アクションボタンがある場合
    if (data.actions) {
      options.actions = data.actions;
    }
  }

  event.waitUntil(self.registration.showNotification(title, options));
});

// 通知クリックイベントのリスナー
self.addEventListener("notificationclick", function (event) {
  event.notification.close(); // 通知を閉じる

  // クリック時の遷移先URL
  const urlToOpen = event.notification.data.url;

  event.waitUntil(
    clients
      .matchAll({
        type: "window",
        includeUncontrolled: true,
      })
      .then(function (windowClients) {
        // すでに開いているタブがあればフォーカスする
        for (let i = 0; i < windowClients.length; i++) {
          const client = windowClients[i];
          if (client.url === urlToOpen && "focus" in client) {
            return client.focus();
          }
        }
        // 開いていなければ新しいウィンドウで開く
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});
