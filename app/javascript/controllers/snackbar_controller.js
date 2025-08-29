import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['actionButton', 'countdown'];

  static values = {
    timeout: { type: Number, default: 6 },
  };

  connect() {
    setTimeout(() => {
      this.element.classList.remove('opacity-0', 'translate-x-16');

      if (this.hasCountdownTarget) {
        this.countdownTarget.style.animation = `notificationCountdown linear ${this.timeoutValue}s`;
      }
    }, 500);

    this.timeoutId = setTimeout(() => {
      this.close();
    }, this.timeoutValue * 1000 + 500);

    if (this.hasActionButtonTarget) {
      this.actionButtonTarget.addEventListener('click', () => {
        this.close();
      });
    }
  }

  disconnect() {
    if (this.hasActionButtonTarget) {
      this.actionButtonTarget.removeEventListener('click', () => {
        this.close();
      });
    }
  }

  close() {
    this.element.classList.add('opacity-0');

    setTimeout(() => {
      this.element.remove();
    }, 300);
  }
}
