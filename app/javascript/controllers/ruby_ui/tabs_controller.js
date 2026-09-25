import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="ruby-ui--tabs"
export default class extends Controller {
  static targets = ["trigger", "content"];
  static values = { active: String };

  connect() {
    if (!this.hasActiveValue && this.triggerTargets.length > 0) {
      this.activeValue = this.triggerTargets[0].dataset.value;
    }
    // A morphing page refresh (e.g. a redirect back to the same URL) resets the tab markup to the
    // server's all-hidden state without reconnecting this controller, so show the active tab again.
    this.render = this.render.bind(this);
    document.addEventListener("turbo:morph", this.render);
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.render);
  }

  show(e) {
    this.activeValue = e.currentTarget.dataset.value;
  }

  activeValueChanged(currentValue, previousValue) {
    if (currentValue == "" || currentValue == previousValue) return;

    this.render();
  }

  render() {
    this.contentTargets.forEach((el) => {
      el.classList.add("hidden");
    });

    this.triggerTargets.forEach((el) => {
      el.dataset.state = "inactive";
    });

    this.activeContentTarget() &&
      this.activeContentTarget().classList.remove("hidden");
    this.activeTriggerTarget() && (this.activeTriggerTarget().dataset.state = "active");
  }

  activeTriggerTarget() {
    return this.triggerTargets.find(
      (el) => el.dataset.value == this.activeValue,
    );
  }

  activeContentTarget() {
    return this.contentTargets.find(
      (el) => el.dataset.value == this.activeValue,
    );
  }
}
