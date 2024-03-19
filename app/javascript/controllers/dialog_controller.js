import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["backdrop", "content"];

  static values = { open: { type: Boolean, default: false } };

  toggle() {
    if (this.openValue) {
      this.hide();
    } else {
      this.show();
    }
  }

  show() {
    this.openValue = true;
    this.backdropTarget.classList.remove("hidden");
  }

  hide() {
    this.openValue = false;
    this.backdropTarget.classList.add("hidden");
  }

  closeBackground(e) {
    if (
      !this.contentTarget.contains(e.target)
      && this.backdropTarget.contains(e.target)
    ) {
      this.hide();
    }
  }
}
