import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="email-change"
// Asks for the current password only once the email address has been edited.
// The server enforces the same rule; this just keeps the field out of the way
// for people who are only fixing their name.
export default class extends Controller {
  static targets = ["email", "confirmation"]
  static values = { original: String }

  connect() {
    this.toggle()
  }

  toggle() {
    const changed = this.normalize(this.emailTarget.value) !== this.normalize(this.originalValue)

    this.confirmationTarget.classList.toggle("hidden", !changed)
    this.confirmationTarget.querySelectorAll("input").forEach((input) => {
      input.required = changed
    })
  }

  // Matches how the server stores addresses, so retyping the same one in
  // another case doesn't count as a change.
  normalize(email) {
    return email.trim().toLowerCase()
  }
}
