import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="refresh-minutes"
export default class extends Controller {
  static targets = ['minutes'];
  static values = {
    active: Boolean,
    minutes: Number
  };

  connect() {
    this.toggleRefresh()
    window.addEventListener('turbo:render', () => this.toggleRefresh());
  }

  toggleRefresh() {
    if (!this.intervalId && this.activeValue) {
      let totalMinutes = this.minutesValue;
      this.intervalId = setInterval(() => {
        totalMinutes += 1;
        this.minutesTarget.textContent = this.formatTime(totalMinutes);
      }, 1000 * 60);
    } else if (this.intervalId && !this.activeValue) {
      this._clearInterval()
    };
  }

  formatTime(mins) {
    const hours = Math.trunc(mins / 60);
    const minutes = (mins % 60).toString().padStart(2, "0");
    return `${hours}:${minutes}`;
  }

  disconnect() {
    this._clearInterval()
  }

  _clearInterval() {
    clearInterval(this.intervalId);
    this.intervalId = undefined;
  }
}
