import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="input"
export default class extends Controller {
  static targets = ["clone", "submitButton"];

  static values = {
    activeText: { type: String, default: '' },
    inactiveText: { type: String, default: '' },
  };

  connect() {
    this.handleSubmitButtonValue(this.cloneTarget.value);
  }

  cloneValue(e) {
    const eventTargetValue = e.target.value;
    this.cloneTarget.value = this.stringToTime(eventTargetValue);
    this.handleSubmitButtonValue(eventTargetValue);
  }

  stringToTime(inputString) {
    // Only allow numbers and colon
    if (!/^[0-9:]+$/.test(inputString)) return NaN;

    const [hours, minutes] = inputString.split(":").map(str => parseInt(str) || 0);

    return (hours * 60) + (minutes || 0);
  }

  handleSubmitButtonValue(inputValue) {
    if(this.hasSubmitButtonTarget) {
      this.submitButtonTarget.value = !!inputValue ? this.activeTextValue : this.inactiveTextValue;
    }
  }
}
