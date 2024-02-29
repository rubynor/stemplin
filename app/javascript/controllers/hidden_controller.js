import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["textField", "button"];

  toggleVisibility() {
    this.textFieldTarget.classList.toggle("hidden");
    this.buttonTarget.classList.toggle("hidden");
  }
}
