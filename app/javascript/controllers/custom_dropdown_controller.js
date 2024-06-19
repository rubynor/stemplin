import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['trigger', 'content'];
  static values = { closeBackgroundDelay: Boolean };

  triggerTargetConnected() {
    this.doStuff()
    window.addEventListener('resize', () => this.doStuff());
  }

  doStuff() {
    this.screenHeight = screen.height
    this.originalRect = this.triggerTarget.getBoundingClientRect();
    this.triggerTop = this.originalRect.bottom;

    if (!this.originalRect) {
      this.originalRect = this.triggerTarget.getBoundingClientRect();
      this.triggerTop = this.originalRect.bottom;
    }

    const availableContentSpace = this.screenHeight - this.triggerTop - 10;

    const contentRect = this.contentTarget.getBoundingClientRect();

    if (contentRect.height > availableContentSpace) {
      this.contentTarget.style.bottom = -Math.abs(availableContentSpace) + "px";
    } else {
      this.contentTarget.style.bottom = "unset";
    }
  }

  toggleContent(isActionOpen = true) {
    this.closeOtherDropdowns();
    this.contentTarget.classList.toggle('hidden', !isActionOpen);
    this.contentTarget.classList.toggle('absolute', isActionOpen);
  }

  closeOtherDropdowns() {
    document.querySelectorAll('.custom-dropdown-component-content').forEach(content => {
      content.classList.add('hidden');
      content.classList.remove('absolute');
    });
  }

  isOpen() {
    return !this.contentTarget.classList.contains('hidden');
  }

  closeWithKeyboard(event) {
    if (event.code === 'Escape' && this.isOpen()) {
      this.toggleContent(false);
    }
  }

  closeBackground(event) {
    if (!this.element.contains(event.target) && this.isOpen()) {
      setTimeout(() => this.toggleContent(false), this.closeBackgroundDelayValue ? 300 : 0);
    }
  }
}
