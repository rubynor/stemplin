import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="show-on-value"
// Shows or hides the element based on the value of the input
export default class extends Controller {
  static targets = ['input', 'toggle'];
  static values = { accepted: Array };

  initialize() {
    document.addEventListener('turbo:morph', this.updateVisibility.bind(this));
  }

  connect() {
    this.updateVisibility();
    this.inputTarget.addEventListener('input', this.updateVisibility.bind(this));
  }

  disconnect() {
    this.inputTarget.removeEventListener('input', this.updateVisibility.bind(this));
  }

  updateVisibility() {
    if (this.acceptedValue.includes(this.inputTarget.value)) {
      this.toggleTarget.classList.remove('hidden');
    } else {
      this.toggleTarget.classList.add('hidden');
    }
  }
}
