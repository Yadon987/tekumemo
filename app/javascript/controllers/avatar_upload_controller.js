import { Controller } from "@hotwired/stimulus";

// アバター画像のアップロードプレビューと選択状態の制御を行うコントローラー
export default class extends Controller {
  static targets = [
    "preview",
    "input",
    "radio",
    "optionCard",
    "dropZone",
    "errorMessage",
    "modal",
    "uploadIconContainer"
  ];

  connect() {
    this.updateUI();
  }

  // モーダルを開く
  openModal(e) {
    if (e) e.preventDefault()
    this.modalTarget.showModal()
  }

  // モーダルを閉じる
  closeModal(e) {
    if (e) e.preventDefault()
    this.modalTarget.close()
  }

  // 背景クリックで閉じる
  clickOutside(e) {
    if (e.target === this.modalTarget) {
      this.closeModal(e)
    }
  }

  // ドラッグオーバー時：スタイル変更でユーザーに通知
  dragOver(e) {
    e.preventDefault();
    e.stopPropagation();
    this.dropZoneTarget.classList.add(
      "border-blue-500",
      "bg-blue-50",
      "dark:bg-blue-900/20",
      "scale-[1.02]"
    );
    this.dropZoneTarget.classList.remove(
      "border-gray-300",
      "dark:border-gray-600"
    );
  }

  // ドラッグリーブ時：スタイルを元に戻す
  dragLeave(e) {
    e.preventDefault();
    e.stopPropagation();
    this.resetDropZoneStyle();
  }

  // ドロップ時：ファイルを受け取って処理
  drop(e) {
    e.preventDefault();
    e.stopPropagation();
    this.resetDropZoneStyle();

    const files = e.dataTransfer.files;
    if (files.length > 0) {
      this.inputTarget.files = files;
      this.previewImage();
    }
  }

  resetDropZoneStyle() {
    this.dropZoneTarget.classList.remove(
      "border-blue-500",
      "bg-blue-50",
      "dark:bg-blue-900/20",
      "scale-[1.02]"
    );
    this.dropZoneTarget.classList.add(
      "border-gray-300",
      "dark:border-gray-600"
    );
  }

  // ファイルが選択された時の処理
  previewImage() {
    const file = this.inputTarget.files[0];
    if (!file) return;

    // バリデーション実行
    if (!this.validateFile(file)) return;

    // エラーをクリア
    this.hideError();

    // FileReaderで画像を読み込んでプレビュー表示
    const reader = new FileReader();
    reader.onload = (e) => {
      // アップロードアイコンの更新
      if (this.hasUploadIconContainerTarget) {
        this.uploadIconContainerTarget.innerHTML = `<img src="${e.target.result}" class="w-8 h-8 rounded-full object-cover shadow-sm">`;
      }
    };
    reader.readAsDataURL(file);

    // 自動的に「アップロード画像」を選択状態にする
    this.radioTargets.find((r) => r.value === "uploaded").checked = true;
    this.updateUI();
  }

  // クライアントサイドバリデーション
  validateFile(file) {
    const maxSize = 5 * 1024 * 1024; // 5MB
    const allowedTypes = ["image/jpeg", "image/png", "image/gif", "image/webp"];

    if (!allowedTypes.includes(file.type)) {
      this.showError(
        "対応していないファイル形式です。画像ファイル（JPG, PNG, GIF, WEBP）を選択してください。"
      );
      return false;
    }

    if (file.size > maxSize) {
      this.showError(
        "ファイルサイズが大きすぎます。5MB以下の画像を選択してください。"
      );
      return false;
    }

    return true;
  }

  showError(message) {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message;
      this.errorMessageTarget.classList.remove("hidden");

      // エラー時は入力をリセット
      this.inputTarget.value = "";
    } else {
      alert(message);
    }
  }

  hideError() {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.classList.add("hidden");
    }
  }

  // ラジオボタンが変更された時の処理
  updateUI() {
    const selectedValue = this.radioTargets.find((r) => r.checked).value;

    // 選択されたカードを強調表示
    this.optionCardTargets.forEach((card) => {
      const radioValue = card.dataset.value;
      if (radioValue === selectedValue) {
        card.classList.add(
          "ring-2",
          "ring-blue-500",
          "bg-blue-50",
          "dark:bg-blue-900/20"
        );
        card.classList.remove("border-gray-200", "dark:border-gray-700");
      } else {
        card.classList.remove(
          "ring-2",
          "ring-blue-500",
          "bg-blue-50",
          "dark:bg-blue-900/20"
        );
        card.classList.add("border-gray-200", "dark:border-gray-700");
      }
    });
  }

  // 削除確認モーダルを表示
  showDeleteModal(e) {
    e.preventDefault();
    e.stopPropagation(); // ラベルへのイベント伝播を防ぐ
    const modal = document.getElementById("avatar_delete_modal");
    if (modal) {
      modal.classList.remove("hidden");
    }
  }

  // 削除確認モーダルを非表示
  hideDeleteModal() {
    const modal = document.getElementById("avatar_delete_modal");
    if (modal) {
      modal.classList.add("hidden");
    }
  }
}
