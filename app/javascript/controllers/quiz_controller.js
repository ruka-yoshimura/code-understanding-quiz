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

    const clickedButton = event.currentTarget;
    const isCorrect = clickedButton.dataset.isCorrect === "true";

    // ローカルでの視覚的フィードバック
    this.optionTargets.forEach((button) => {
      // 常に正解の選択肢を緑色にする
      if (button.dataset.isCorrect === "true") {
        button.style.backgroundColor = "rgba(16, 185, 129, 0.2)";
        button.style.borderColor = "#10b981";
        button.style.color = "#10b981";
      }
    });

    // 不正解を選んだ場合、そのボタンを赤色にする
    if (!isCorrect) {
      clickedButton.style.backgroundColor = "rgba(244, 63, 94, 0.2)";
      clickedButton.style.borderColor = "#f43f5e";
      clickedButton.style.color = "#f43f5e";
    }

    // 解説を表示
    this.explanationTarget.style.display = "block";
  }
}
