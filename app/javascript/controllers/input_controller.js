import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="input"
export default class extends Controller {
  static targets = ["clone"];
  connect() {
  }

  cloneValue(e) {
    const eventTargetValue = e.target.value;
    this.cloneTarget.value = this.stringToTime(eventTargetValue);
  }

  stringToTime(inputString) {
    // Only allow numbers and colon
    if (!/^[0-9:]+$/.test(inputString)) return NaN;

    const [hours, minutes] = inputString.split(":").map(str => parseInt(str) || 0);

    return (hours * 60) + (minutes || 0);
  }
}
