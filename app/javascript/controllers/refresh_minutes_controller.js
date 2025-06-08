import { Controller } from "@hotwired/stimulus"
import moment from "moment";
import momentDurationFormatSetup from "moment-duration-format";

momentDurationFormatSetup(moment); // Setup moment-duration-format plugin

const MINUTE = 1000 * 60;

export default class extends Controller {
  static targets = ['minutes', 'title'];
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
      this.interval = MINUTE;
      this.expected = Date.now() + this.interval;
      this.now = Date.now();
      this.timeoutId = setTimeout(this.selfAdjustingTimeout.bind(this), this.interval);
    }
  }

  selfAdjustingTimeout() {
    if (this.activeValue) {
      this.totalMillis += this.interval;
      const driftMillis = Date.now() - this.expected;
      this.expected += this.interval;

      const formatted = this.formatedStamp();

      this.minutesTarget.textContent = formatted;

      if (this.hasTitleTarget) {
        this.titleTarget.textContent = `${formatted} | Stemplin`;
      }

      this.timeoutId = setTimeout(this.selfAdjustingTimeout.bind(this), Math.max(0, this.interval - driftMillis));
    }
  }
  formatedStamp = () =>
    moment.duration(this.totalMillis, "milliseconds").format(this.formatValue, { trunc: true, trim: false });

  clearCurrentTimeout() {
    if (!this.timeoutId) return;
    clearTimeout(this.timeoutId);
    this.timeoutId = undefined;
  }

}
