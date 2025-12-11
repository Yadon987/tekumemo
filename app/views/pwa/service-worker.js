// てくメモ PWA Service Worker
// バージョン管理：アプリを更新する際はバージョンを上げる
const CACHE_VERSION = 'tekumemo-v2'; // アイコン更新のためバージョンアップ
const CACHE_NAME = `${CACHE_VERSION}`;

// キャッシュ対象のファイル（アプリの起動に最低限必要なもの）
const PRECACHE_URLS = [
  '/',
  '/walks',
  '/posts',
  '/rankings',
  '/icon.png',
  '/512x512.png',
  '/favicon.ico'
];

// ========================================
// 1. インストール時の処理
// ========================================
self.addEventListener('install', (event) => {
  console.log('[Service Worker] Install');

  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('[Service Worker] Pre-caching offline page');
        // 1つずつキャッシュして、どれが失敗するか特定
        return Promise.all(
          PRECACHE_URLS.map(url => {
            return cache.add(url).then(() => {
              console.log('[Service Worker] Cached:', url);
            }).catch(err => {
              console.error('[Service Worker] Failed to cache:', url, err);
            });
          })
        );
      })
      .then(() => {
        console.log('[Service Worker] All files cached successfully');
        return self.skipWaiting();
      })
      .catch(err => {
        console.error('[Service Worker] Installation failed:', err);
      })
  );
});

// ========================================
// 2. アクティベート時の処理（古いキャッシュを削除）
// ========================================
self.addEventListener('activate', (event) => {
  console.log('[Service Worker] Activate');

  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          // 古いバージョンのキャッシュを削除
          if (cacheName !== CACHE_NAME) {
            console.log('[Service Worker] Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => self.clients.claim()) // 即座に制御を取得
  );
});

// ========================================
// 3. フェッチ時の処理（キャッシュ戦略）
// ========================================
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // 同一オリジン以外（CDNなど）は通常のfetch
  if (url.origin !== location.origin) {
    return;
  }

  // POSTリクエスト（フォーム送信など）はキャッシュしない
  if (request.method !== 'GET') {
    return;
  }

  event.respondWith(
    caches.match(request)
      .then((cachedResponse) => {
        // キャッシュ戦略: Stale-While-Revalidate
        // 1. キャッシュがあれば即座に返す
        // 2. 同時にネットワークから最新版を取得してキャッシュ更新

        const fetchPromise = fetch(request)
          .then((networkResponse) => {
            // 成功したレスポンスのみキャッシュ
            if (networkResponse && networkResponse.status === 200) {
              const responseToCache = networkResponse.clone();
              caches.open(CACHE_NAME).then((cache) => {
                cache.put(request, responseToCache);
              });
            }
            return networkResponse;
          })
          .catch((error) => {
            console.log('[Service Worker] Fetch failed:', error);
            // ネットワークエラー時はキャッシュがあればそれを返す
            return cachedResponse;
          });

        // キャッシュがあれば即返し、なければネットワークを待つ
        return cachedResponse || fetchPromise;
      })
  );
});

// ========================================
// 4. プッシュ通知の受信（将来の実装用）
// ========================================
self.addEventListener('push', async (event) => {
  const data = event.data ? event.data.json() : {};
  const title = data.title || 'てくメモ';
  const options = {
    body: data.body || '新しい通知があります',
    icon: '/icon.png',
    badge: '/icon.png',
    data: {
      url: data.url || '/'
    }
  };

  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

// ========================================
// 5. 通知クリック時の処理（将来の実装用）
// ========================================
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const urlToOpen = event.notification.data.url || '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // 既に開いているウィンドウがあれば、そこにフォーカス
        for (let i = 0; i < clientList.length; i++) {
          const client = clientList[i];
          if (client.url === urlToOpen && 'focus' in client) {
            return client.focus();
          }
        }
        // なければ新しいウィンドウを開く
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});
