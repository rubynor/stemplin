import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="toggle-active-class"
export default class extends Controller {
  static values = {
    activeClass: String,
  };

  static targets = ["main", "setTrue", "setFalse"];

  connect() {
    const value = this.mainTarget.checked;
    if (value) {
      this.setTrueTarget.classList.add(this.activeClassValue);
    } else {
      this.setFalseTarget.classList.add(this.activeClassValue);
    }
  }

  updateClass() {
    const value = this.mainTarget.checked;
    if (value) {
      this.setFalseTarget.classList.remove(this.activeClassValue);
      this.setTrueTarget.classList.add(this.activeClassValue);
    } else {
      this.setTrueTarget.classList.remove(this.activeClassValue);
      this.setFalseTarget.classList.add(this.activeClassValue);
    }
  }
}
