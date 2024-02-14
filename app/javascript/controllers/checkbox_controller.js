import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button", "checkbox"];

  connect() {}

  check() {
    this.checkboxTarget.checked = true;
  }

  uncheck() {
    this.checkboxTarget.checked = false;
  }
}
