import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button"];
  static values = {
    initial: String,
  };

  changed(event) {
    const current = event.target.value;

    if (current === this.initialValue) {
      this.buttonTarget.classList.add("hidden");
    } else {
      this.buttonTarget.classList.remove("hidden");
    }
  }
}
