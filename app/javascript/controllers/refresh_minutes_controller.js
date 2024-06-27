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
  }

  disconnect() {
    this.clearCurrentInterval();
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
