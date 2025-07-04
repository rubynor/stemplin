import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "modal" ]

  connect() {
    window.addEventListener('click', this.closeModal.bind(this));
  }

  disconnect() {
    window.removeEventListener('click', this.closeModal.bind(this));
  }

  toggle() {
    this.modalTarget.classList.toggle('hidden');
  }

  closeModal(event) {
    if (event.target === this.modalTarget) {
      this.modalTarget.classList.add("hidden");
    }
  }

  preventClose(event) {
    event.stopPropagation();
  }
}
