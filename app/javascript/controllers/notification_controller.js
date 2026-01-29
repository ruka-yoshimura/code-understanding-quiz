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

  connect() {
    console.log(
      "NotificationController connected",
      this.typeValue,
      this.titleValue,
    );
    if (this.typeValue === "toast") {
      this.toast();
    } else if (this.typeValue === "levelUp") {
      this.levelUp();
    } else if (this.typeValue === "popup") {
      this.popup();
    }
  }

  // 中心に出るポップアップ（正解・不正解用）
  popup() {
    const title = this.titleValue;
    const html = this.htmlValue;
    const icon = this.iconValue || "success";
    const timer = this.timerValue;

    Swal.fire({
      title: title,
      html: html,
      icon: icon,
      timer: 1500,
      showConfirmButton: false,
      backdrop: `
        rgba(0,0,123,0.4)
        left top
        no-repeat
      `,
    });
  }

  // レベルアップ演出
  levelUp() {
    const level = this.levelValue;
    const title = this.titleValue;

    Swal.fire({
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
  toast() {
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

    Toast.fire({
      icon: icon,
      title: title,
    });
  }
}
