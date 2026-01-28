import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["option", "explanation"];

  connect() {
    console.log("Quiz controller connected");
  }

  submit(event) {
    // ボタンの多重クリック防止
    // 注意: 即座にdisabledにするとブラウザによってはフォーム送信がキャンセルされるため、
    // 処理の最後に回すか、setTimeoutを使用する
    setTimeout(() => {
      this.optionTargets.forEach((button) => {
        button.disabled = true;
      });
    }, 0);

    const button = event.currentTarget;
    const isCorrect = button.dataset.isCorrect === "true";

    // ローカルでの視覚的フィードバック
    if (isCorrect) {
      button.style.backgroundColor = "rgba(16, 185, 129, 0.2)";
      button.style.borderColor = "#10b981";
      button.style.color = "#10b981";
    } else {
      button.style.backgroundColor = "rgba(244, 63, 94, 0.2)";
      button.style.borderColor = "#f43f5e";
      button.style.color = "#f43f5e";
    }

    // 解説を表示
    this.explanationTarget.style.display = "block";
  }
}
