import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    activeClass: String,
  };

  static targets = [
    "main",
    "setTrue",
    "setFalse",
    "billableRates",
    "input1",
    "input2",
  ];

  connect() {
    this.updateClass();
  }

  updateClass() {
    const value = this.mainTarget.checked;
    if (value) {
      this.setFalseTarget.classList.remove(this.activeClassValue);
      this.setTrueTarget.classList.add(this.activeClassValue);
      this.billableRatesTarget.classList.remove("hidden");
    } else {
      this.setTrueTarget.classList.remove(this.activeClassValue);
      this.setFalseTarget.classList.add(this.activeClassValue);
      this.billableRatesTarget.classList.add("hidden");
    }
  }
}
