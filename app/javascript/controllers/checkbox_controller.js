import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button", "checkbox", "checkboxAll"];

  connect() {}

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

  uncheckCheckboxAll() {
    this.checkboxAllTarget.checked = !this.checkboxTargets.find(checkbox => !checkbox.checked);
  }
}
