import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['trigger', 'content'];
  static values = { closeBackgroundDelay: Boolean };

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
