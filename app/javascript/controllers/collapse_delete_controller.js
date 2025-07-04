import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapse-delete"
export default class extends Controller {
  static targets = ['toggleDiv'];

  connect() {
  }
  deleteDiv(event) {
    this.toggleDivTarget.classList.toggle('hidden');
  }

}
