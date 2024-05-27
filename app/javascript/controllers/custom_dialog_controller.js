import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["trigger"];

  connect() {
    this.showPhlexModal();
    this.focusOnInput();
  }

  showPhlexModal() {
    // let's get all divs that have data-controller="dismissable" and remove them from the DOM
    const dismissableDivs = document.querySelectorAll('div[data-controller="dismissable"]');
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
