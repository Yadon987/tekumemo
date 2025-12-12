import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    vapidPublicKey: String
  }

  connect() {
    // ブラウザがService WorkerとPush APIをサポートしているか確認
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      console.log("Push messaging is not supported")
      this.element.style.display = "none"
    }
  }

  // 通知の購読登録を行う
  async subscribe() {
    try {
      console.log("=== Push Notification Registration Start ===")
      console.log("VAPID Public Key:", this.vapidPublicKeyValue)
      console.log("VAPID Key length:", this.vapidPublicKeyValue.length)

      // 1. 通知権限を要求
      console.log("Requesting notification permission...")
      const permission = await Notification.requestPermission()
      console.log("Permission result:", permission)

      if (permission !== "granted") {
        alert("通知を許可してください")
        return
      }

      // 2. Service Workerを登録して、完全に有効になるまで待つ
      console.log("Registering service worker...")
      const registration = await navigator.serviceWorker.register("/service-worker.js")
      console.log("Service Worker registered, waiting for ready state...")
      await navigator.serviceWorker.ready
      console.log("Service Worker is ready")

      // 3. 既存の購読を確認
      console.log("Checking for existing subscription...")
      let subscription = await registration.pushManager.getSubscription()
      console.log("Existing subscription:", subscription)

      // 既存の購読があれば削除
      if (subscription) {
        console.log("Unsubscribing from existing subscription...")
        await subscription.unsubscribe()
        console.log("Unsubscribed successfully")
      }

      // 4. 新しく購読を登録
      console.log("Subscribing to push notifications...")
      console.log("Converting VAPID key...")
      const applicationServerKey = this.urlBase64ToUint8Array(this.vapidPublicKeyValue)
      console.log("Converted key (first 10 bytes):", Array.from(applicationServerKey.slice(0, 10)))

      subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: applicationServerKey
      })
      console.log("Subscription successful:", subscription)

      // 5. 購読情報をサーバーに送信
      console.log("Sending subscription to server...")
      await this.sendSubscriptionToServer(subscription)
      console.log("=== Push Notification Registration Complete ===")

      alert("通知設定が完了しました！")
    } catch (error) {
      console.error("=== Push Notification Registration Failed ===")
      console.error("Error type:", error.constructor.name)
      console.error("Error name:", error.name)
      console.error("Error message:", error.message)
      console.error("Error stack:", error.stack)
      console.error("Full error object:", error)
      alert("通知設定に失敗しました。ブラウザの設定を確認してください。\nエラー: " + error.message)
    }
  }

  // サーバーに購読情報を送信
  async sendSubscriptionToServer(subscription) {
    const response = await fetch("/web_push_subscriptions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify(subscription)
    })

    if (!response.ok) {
      throw new Error("Failed to send subscription to server")
    }
  }

  // VAPIDキーの変換用ユーティリティ
  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
  }
}
