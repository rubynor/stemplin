import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['content'];

  static values = { initialStatus: Boolean };

  connect() {
    this.toggleElement({ params: { enable: this.initialStatusValue } });
    document.addEventListener('turbo:morph', () => {
      this.toggleElement({ params: { enable: this.initialStatusValue } });
    });
  }

  disconnect() {
    document.removeEventListener('turbo:morph', () => {
      this.toggleElement({ params: { enable: this.initialStatusValue } });
    });
  }

  toggleElement({ params: { enable } }) {
    ['opacity-30', 'pointer-events-none', 'cursor-not-allowed'].forEach(
      (className) => this.contentTarget.classList.toggle(className, !enable)
    );
    if (enable) {
      this.contentTarget.removeAttribute('disabled');
    } else {
      this.contentTarget.setAttribute('disabled', 'disabled');
    }
  }
}
