import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    type: String,
    level: Number,
    title: String,
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
    }
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
