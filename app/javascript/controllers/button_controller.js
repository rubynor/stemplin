import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button"];

  connect() {
    this.toggleButtonColor(
      document.getElementById("billable_project_checkbox").checked
    );
  }

  toggleActive() {
    const checkbox = document.getElementById("billable_project_checkbox");
    checkbox.checked = !checkbox.checked;
    this.toggleButtonColor(checkbox.checked);
  }

  toggleButtonColor(checked) {
    const button = this.element.querySelector("button");
    if (checked) {
      button.style.backgroundColor = "lightsalmon";
      button.style.color = "";
      button.style.borderColor = "darkorange";
    } else {
      button.style.backgroundColor = "";
      button.style.color = "";
      button.style.borderColor = "";
    }
  }
}
