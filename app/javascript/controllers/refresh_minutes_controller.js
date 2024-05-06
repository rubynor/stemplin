import { Controller } from "@hotwired/stimulus"
import { format, minutesToMilliseconds } from 'date-fns';

// Connects to data-controller="refresh-minutes"
export default class extends Controller {
  static targets = ['minutes'];
  static values = {
    active: Boolean,
    minutes: Number,
    startTime: String,
    format: String,
  };

  connect() {
    this.toggleRefresh();
    window.addEventListener('turbo:morph', (event) => this.toggleRefresh(event));
  }

  toggleRefresh() {
    this.clearCurrentInterval();
    if (this.activeValue && !this.intervalId) {

      this.intervalId = setInterval(() => {
        this.minutesTarget.textContent = this.formatTime();
      }, 1000);
    }
  }

  formatTime() {
    let diffDate = new Date(1970, 0);
    const currentDate = new Date(Date.now());
    const startDate = new Date(this.startTimeValue);
    const savedTimeMillis = minutesToMilliseconds(this.minutesValue);

    diffDate.setMilliseconds(currentDate - startDate + savedTimeMillis);

    return format(diffDate, this.formatValue);
  }

  disconnect() {
    this.clearCurrentInterval();
    window.removeEventListener('turbo:morph', (event) => this.toggleRefresh(event));
  }

  clearCurrentInterval() {
    if (!this.intervalId) return;
    clearInterval(this.intervalId);
    this.intervalId = undefined;
  }
}
