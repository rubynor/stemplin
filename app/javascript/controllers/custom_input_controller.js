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
    e.target.value = this.decimalToTimestamp(e.target.value);

    this.cloneTarget.value = this.stringToTime(e.target.value);

    this.handleSubmitButtonValue(e.target.value);
  }

  decimalToTimestamp(decimalString) {
    if (decimalString.includes(':')) return decimalString;

    const contentString = decimalString.replace(',', '.');
    const decimal = parseFloat(contentString);

    const hours = Math.floor(decimal);
    let minutes = Math.round((decimal - hours) * 60);

    if (minutes < 10) minutes = '0' + minutes;

    return `${hours}:${minutes}`;
  }

  stringToTime(inputString) {
    // Only allow numbers and colon
    if (!/^[0-9:]+$/.test(inputString)) return NaN;

    const [hours, minutes] = inputString.split(":").map(str => parseInt(str) || 0);

    return (hours * 60) + (minutes || 0);
  }

  handleSubmitButtonValue(inputValue) {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.innerText = (!!inputValue && inputValue !== "0") ? this.activeTextValue : this.inactiveTextValue;
    }
  }
}
