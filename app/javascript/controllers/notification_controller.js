import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    type: String,
    level: Number,
    title: String,
    html: String,
    icon: String,
    timer: { type: Number, default: 3000 },
  };

  // 連続する通知を管理するための静的キュー
  static queue = [];
  static isProcessing = false;

  connect() {
    this.enqueue(() => this.showNotification());
  }

  enqueue(action) {
    this.constructor.queue.push(action);
    this.processQueue();
  }

  processQueue() {
    if (this.constructor.isProcessing) return;
    if (this.constructor.queue.length === 0) return;

    this.constructor.isProcessing = true;
    const action = this.constructor.queue.shift();

    action().then(() => {
      this.constructor.isProcessing = false;
      // Small delay between notifications for better UX
      setTimeout(() => this.processQueue(), 300);
    });
  }

  async showNotification() {
    if (this.typeValue === "toast") {
      return this.toast();
    } else if (this.typeValue === "levelUp") {
      return this.levelUp();
    } else if (this.typeValue === "popup") {
      return this.popup();
    }
    return Promise.resolve();
  }

  // 中心に出るポップアップ（正解・不正解用）
  async popup() {
    const title = this.titleValue;
    const html = this.htmlValue;
    const icon = this.iconValue || "success";
    const timer = this.timerValue;

    return Swal.fire({
      title: title,
      html: html,
      icon: icon,
      timer: timer,
      showConfirmButton: false,
      backdrop: `
        rgba(0,0,123,0.4)
        left top
        no-repeat
      `,
    });
  }

  // レベルアップ演出
  async levelUp() {
    const level = this.levelValue;
    const title = this.titleValue;

    return Swal.fire({
      title: "Level Up!",
      html: `レベル <strong>${level}</strong> に到達しました！<br>称号: <strong>${title}</strong>`,
      icon: "success",
      confirmButtonText: "やった！",
      buttonsStyling: false,
      customClass: {
        confirmButton: "button primary",
        popup: "quiz-card",
        title: "text-success",
      },
      showClass: {
        popup: "animate__animated animate__bounceIn",
      },
    });
  }

  // トースト通知（XP獲得など）
  async toast() {
    const title = this.titleValue;
    const icon = this.iconValue || "success";
    const timer = this.timerValue;

    const Toast = Swal.mixin({
      toast: true,
      position: "top-end",
      showConfirmButton: false,
      timer: timer,
      timerProgressBar: true,
      didOpen: (toast) => {
        toast.addEventListener("mouseenter", Swal.stopTimer);
        toast.addEventListener("mouseleave", Swal.resumeTimer);
      },
    });

    return Toast.fire({
      icon: icon,
      title: title,
    });
  }
}
