import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["trigger"];

  connect() {
    this.showPhlexModal();
    this.focusOnInput();
  }

  showPhlexModal() {
    // Remove any existing open dialogs from the DOM before opening a new one
    const dismissableDivs = document.querySelectorAll('body > div[data-controller="ruby-ui--dialog"]');
    dismissableDivs?.forEach((el) => el?.remove());

    this.triggerTarget.click();
  }

  focusOnInput() {
    const autofocusInput = document.querySelector("[data-state=open] form [autofocus=autofocus]");
    if (!autofocusInput) return;
    autofocusInput.focus();
    autofocusInput.selectionStart = autofocusInput.value.length;
  }
}
