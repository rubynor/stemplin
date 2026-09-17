import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button", "checkbox", "checkboxAll"];
  static values = { badge: String };

  connect() {
    this.element.addEventListener("turbo:frame-load", () => this.updateCheckboxAll());
  }

  checkboxAllTargetConnected() {
    this.updateCheckboxAll();
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
    this.updateBadge();
  }

  updateCheckboxAll() {
    this.checkboxAllTarget.checked = this.allCheckboxesChecked();
    this.updateBadge();
  }

  allCheckboxesChecked() {
    if (this.checkboxTargets.length === 0) return false;
    return !this.checkboxTargets.find(checkbox => !checkbox.checked);
  }

  // Keeps the count shown on the (closed) dropdown trigger in sync with the selection
  updateBadge() {
    if (!this.hasBadgeValue) return;

    const badgeElement = document.querySelector(`[data-checkbox-badge="${this.badgeValue}"]`);
    if (!badgeElement) return;

    badgeElement.textContent = this.checkboxTargets.filter(checkbox => checkbox.checked).length;
  }
}
