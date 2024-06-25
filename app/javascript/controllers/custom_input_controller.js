import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="input"
export default class extends Controller {
  static targets = ["input", "hiddenInput", "submitButton"];

  static values = {
    activeText: { type: String, default: '' },
    inactiveText: { type: String, default: '' },
  };

  connect() {
    this.handleSubmitButtonValue(this.hiddenInputTarget.value);
  }

  updateFormat() {
    this.inputTarget.value = this.decimalToTimestamp(this.inputTarget.value);
    this.updatehiddenInput();
  }

  updatehiddenInput() {
    this.hiddenInputTarget.value = this.stringToTime(this.inputTarget.value);
    this.handleSubmitButtonValue(this.hiddenInputTarget.value);
  }

  decimalToTimestamp(decimalString) {
    if (decimalString.trim() === "") return "";
    if (decimalString.includes(':')) return decimalString;

    const contentString = decimalString.replace(',', '.');
    const decimal = parseFloat(contentString);
    if (isNaN(decimal)) return decimalString;

    const hours = Math.floor(decimal);
    let minutes = Math.round((decimal - hours) * 60);

    if (minutes < 10) minutes = '0' + minutes;

    return `${hours}:${minutes}`;
  }

  stringToTime(inputString) {
    // Only allow numbers and colon
    if (inputString.trim() === "") return 0;
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
