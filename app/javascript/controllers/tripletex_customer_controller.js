import { Controller } from "@hotwired/stimulus"

// Pre-fills the client name from the chosen Tripletex customer when the name is still empty.
export default class extends Controller {
    static targets = ["name"]

    fillName(event) {
        const name = event.target.selectedOptions[0]?.dataset.name
        if (name && this.hasNameTarget && this.nameTarget.value.trim() === "") {
            this.nameTarget.value = name
        }
    }
}
