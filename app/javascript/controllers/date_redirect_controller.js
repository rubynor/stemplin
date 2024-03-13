import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
  }

  redirectToToday() {
    window.location.href = "/time_regs";
  }
}