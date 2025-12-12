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
      console.log("VAPID Public Key:", this.vapidPublicKeyValue)

      // 1. 通知権限を要求
      const permission = await Notification.requestPermission()
      if (permission !== "granted") {
        alert("通知を許可してください")
        return
      }

      // 2. Service Workerを登録して、完全に有効になるまで待つ
      const registration = await navigator.serviceWorker.register("/service-worker.js")
      await navigator.serviceWorker.ready

      // 3. 既存の購読を確認
      let subscription = await registration.pushManager.getSubscription()

      // 既存の購読があれば削除
      if (subscription) {
        await subscription.unsubscribe()
      }

      // 4. 新しく購読を登録
      subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(this.vapidPublicKeyValue)
      })

      // 5. 購読情報をサーバーに送信
      await this.sendSubscriptionToServer(subscription)

      alert("通知設定が完了しました！")
    } catch (error) {
      console.error("Unable to subscribe to push.", error)
      console.error("Error details:", error.name, error.message)
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
