import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button", "checkbox", "checkboxAll"];

  connect() {
    this.element.addEventListener("turbo:frame-load", () => this.updateCheckboxAll());
  }

  check() {
    this.checkboxTarget.checked = true;
  }

  uncheck() {
    this.checkboxTarget.checked = false;
  }

  toggleAll(e) {
    this.checkboxTargets.forEach(checkBox => {
      checkBox.checked = e.target.checked;
    })
  }

  updateCheckboxAll() {
    this.checkboxAllTarget.checked = this.allCheckboxesChecked();
  }

  allCheckboxesChecked() {
    if (this.checkboxTargets.length === 0) return false;
    return !this.checkboxTargets.find(checkbox => !checkbox.checked);
  }
}
