import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="report-edit"
export default class extends Controller {
  static targets = ['toggleDiv'];
  connect() {
  }

  // toggles hidden on the edit form
  editReport(event) {
    this.toggleDivTarget.classList.toggle('hidden');
  }
}
