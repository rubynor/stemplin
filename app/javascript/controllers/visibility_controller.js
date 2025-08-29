import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="visibility"
export default class extends Controller {
  static targets = [ "hideable" ]
  connect() {
  }

  showTargetsIfCustom(event) {
    event.target.value === "custom" ? this.showTargets() : this.hideTargets();
  }

  hideTargets() {
    this.hideableTargets.forEach(el => el.classList.add("hidden"));
  }

  showTargets() {
    this.hideableTargets.forEach(el => el.classList.remove("hidden"));
  }

  toggleTargets() {
    this.hideableTargets.forEach(el => el.classList.toggle("hidden"));
  }
}
