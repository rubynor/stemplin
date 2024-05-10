import { Controller } from "@hotwired/stimulus"
import moment from "moment";
import momentDurationFormatSetup from "moment-duration-format";

momentDurationFormatSetup(moment); // Setup moment-duration-format plugin

const intervalLength = 1000;

// Connects to data-controller="refresh-minutes"
export default class extends Controller {
  static targets = ['minutes'];
  static values = {
    active: Boolean,
    minutes: Number,
    format: String,
  };

  connect() {
    this.totalMillis = this.minutesValue * 60000;
    this.toggleRefresh();
    window.addEventListener('turbo:morph', (event) => this.toggleRefresh(event));
  }

  disconnect() {
    this.clearCurrentInterval();
    window.removeEventListener('turbo:morph', (event) => this.toggleRefresh(event));
  }

  toggleRefresh() {
    this.clearCurrentInterval();
    if (this.activeValue && !this.intervalId) {
      this.intervalId = setInterval(() => {
        this.totalMillis += intervalLength;
        this.minutesTarget.textContent = this.formatedStamp();
      }, intervalLength);
    }
  }

  clearCurrentInterval() {
    if (!this.intervalId) return;
    clearInterval(this.intervalId);
    this.intervalId = undefined;
  }

  formatedStamp = () => moment.duration(this.totalMillis, "milliseconds").format(this.formatValue, { trunc: true, trim: false });
}
