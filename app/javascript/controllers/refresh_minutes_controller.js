import { Controller } from "@hotwired/stimulus"
import moment from "moment";
import momentDurationFormatSetup from "moment-duration-format";

momentDurationFormatSetup(moment); // Setup moment-duration-format plugin

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
  }

  disconnect() {
    this.clearCurrentTimeout();
  }

  minutesValueChanged() {
    this.totalMillis = this.minutesValue * 60000;
  }

  activeValueChanged() {
    this.toggleRefresh();
  }

  formatValueChanged() {
    this.toggleRefresh();
  }

  toggleRefresh() {
    this.clearCurrentTimeout();
    if (this.activeValue && !this.timeoutId) {
      this.interval = 1000;
      this.expected = Date.now() + this.interval;
      this.now = Date.now();

      // Start self adjusting timer
      this.timeoutId = setTimeout(this.selfAdjustingTimeout.bind(this), this.interval);
    }
  }

  selfAdjustingTimeout() {
    if (this.activeValue) {
      this.totalMillis += this.interval;

      // Calculates time drifting
      const driftMillis = Date.now() - this.expected;
      this.expected += this.interval;

      this.minutesTarget.textContent = this.formatedStamp();
      this.timeoutId = setTimeout(this.selfAdjustingTimeout.bind(this), Math.max(0, this.interval - driftMillis));
    }
  }

  clearCurrentTimeout() {
    if (!this.timeoutId) return;
    clearTimeout(this.timeoutId);
    this.timeoutId = undefined;
  }

  formatedStamp = () => moment.duration(this.totalMillis, "milliseconds").format(this.formatValue, { trunc: true, trim: false });
}
