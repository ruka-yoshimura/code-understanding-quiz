import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["option", "explanation"];

  connect() {
    // Turboキャッシュ等で残った表示状態をリセット
    if (this.hasExplanationTarget) {
      this.explanationTarget.classList.add("hidden");
    }
    this.optionTargets.forEach((button) => {
      button.disabled = false;
      button.classList.remove("is-correct", "is-incorrect");
    });
  }

  submit(event) {
    // ボタンの多重クリック防止
    setTimeout(() => {
      this.optionTargets.forEach((button) => {
        button.disabled = true;
      });
    }, 0);

    const clickedButton = event.currentTarget;
    const isCorrect = clickedButton.dataset.isCorrect === "true";

    // ローカルでの視覚的フィードバック
    this.optionTargets.forEach((button) => {
      // 常に正解の選択肢を強調する
      if (button.dataset.isCorrect === "true") {
        button.classList.add("is-correct");
      }
    });

    // 不正解を選んだ場合、そのボタンを強調する
    if (!isCorrect) {
      clickedButton.classList.add("is-incorrect");
    }

    // 解説を表示
    this.explanationTarget.classList.remove("hidden");
  }
}
