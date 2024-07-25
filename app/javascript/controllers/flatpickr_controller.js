import Flatpickr from 'stimulus-flatpickr'
import Rails from "@rails/ujs";
import moment from 'moment';

import 'flatpickr/dist/l10n/no'

const locales = {
  "en": "en",
  "nb": "no",
}

// Connects to data-controller="flatpickr"
export default class extends Flatpickr {
  static values = {
    autoSubmit: Boolean,
    fitWidth: Boolean,
    locale: { type: String, default: "en" },
  };

  initialize() {
    this.config = {
      locale: locales[this.localeValue],
      dateFormat: "YYYY-MM-DD",
      formatDate: this.formatDate,
      parseDate: this.parseDate,
    }
  }

  connect() {
    super.connect();
    this.updateWidth();
  }

  change(selectedDates, dateStr, instance) {
    if (this.autoSubmitValue) {
      const form = this.element.closest("form");
      if (form)
        Rails.fire(form, "submit");
    }
    this.updateWidth();
  }

  updateWidth() {
    if (this.fitWidthValue) {
      if (this.fp.altInput && this.fp.altInput.value)
        this.fp.altInput.size = this.fp.altInput.value.length;
      else if (this.fp.input && this.fp.input.value)
        this.fp.input.size = this.fp.input.value.length
    }
  }

  // moment's date formatting enables us to put raw text in square brackets instead of using flatpickr's escape characters:
  // https://flatpickr.js.org/formatting/#escaping-formatting-tokens
  formatDate(date, format) {
    return moment(date).format(format);
  }

  parseDate(datestr, format) {
    return moment(datestr, format, true).toDate();
  }
}