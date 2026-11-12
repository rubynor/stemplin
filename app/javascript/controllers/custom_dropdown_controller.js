import { Controller } from '@hotwired/stimulus'
import { computePosition, autoUpdate, offset, flip, shift, size } from '@floating-ui/dom'

const MAX_HEIGHT = 320;

export default class extends Controller {
  static targets = ['trigger', 'content'];
  static values = { closeBackgroundDelay: Boolean };

  disconnect() {
    this.stopAutoUpdate?.();
  }

  // Called from the trigger's click action (toggles) or with a boolean.
  toggleContent(open) {
    const shouldOpen = typeof open === 'boolean' ? open : !this.isOpen();

    this.closeOtherDropdowns();
    if (shouldOpen) {
      this.show();
    } else {
      this.hide(this.contentTarget);
    }
  }

  // The panel holds form fields, so it has to stay where it is in the DOM.
  // Promoting it to the browser's top layer lets it escape a dialog's
  // scroll area and stacking context without moving it.
  show() {
    const content = this.contentTarget;
    content.classList.remove('hidden');

    if (typeof content.showPopover !== 'function') {
      content.classList.add('absolute');
      return;
    }

    content.setAttribute('popover', 'manual');
    // Clear the browser's centring and the in-flow offset before measuring.
    Object.assign(content.style, { position: 'fixed', inset: 'auto', left: '0', top: '0', margin: '0' });
    content.showPopover();

    this.stopAutoUpdate?.();
    this.stopAutoUpdate = autoUpdate(this.triggerTarget, content, () => this.position());
  }

  hide(content) {
    content.classList.add('hidden');
    content.classList.remove('absolute');
    if (content.hasAttribute('popover') && content.matches(':popover-open')) {
      content.hidePopover();
    }
    if (content === this.contentTarget) {
      this.stopAutoUpdate?.();
      this.stopAutoUpdate = null;
    }
  }

  position() {
    const content = this.contentTarget;
    // Another dropdown may have closed this one directly.
    if (!this.isOpen()) {
      this.stopAutoUpdate?.();
      this.stopAutoUpdate = null;
      return;
    }

    const matchTriggerWidth = content.classList.contains('w-full');

    computePosition(this.triggerTarget, content, {
      strategy: 'fixed',
      placement: 'bottom-start',
      middleware: [
        offset(8),
        flip({ padding: 8 }),
        shift({ padding: 8 }),
        size({
          padding: 8,
          apply: ({ rects, availableHeight, elements }) => {
            elements.floating.style.maxHeight = `${Math.max(120, Math.min(availableHeight, MAX_HEIGHT))}px`;
            if (matchTriggerWidth) elements.floating.style.width = `${rects.reference.width}px`;
          },
        }),
      ],
    }).then(({ x, y }) => {
      Object.assign(content.style, { left: `${Math.round(x)}px`, top: `${Math.round(y)}px` });
    });
  }

  closeOtherDropdowns() {
    document.querySelectorAll('.custom-dropdown-component-content').forEach(content => {
      if (content !== this.contentTarget) this.hide(content);
    });
  }

  isOpen() {
    return !this.contentTarget.classList.contains('hidden');
  }

  closeWithKeyboard(event) {
    if (event?.code === 'Escape' && this.isOpen()) {
      this.toggleContent(false);
    }
  }

  closeBackground(event) {
    if (!event?.target) return;
    if (!this.element.contains(event.target) && this.isOpen()) {
      setTimeout(() => this.toggleContent(false), this.closeBackgroundDelayValue ? 300 : 0);
    }
  }
}
