import { Controller } from "@hotwired/stimulus"

// Copies `text` to the clipboard and briefly swaps the button label for `copiedLabel`.
export default class extends Controller {
  static targets = ["label"]
  static values = { text: String, copiedLabel: String }

  async copy() {
    await this.write(this.textValue)
    if (!this.hasLabelTarget) return

    const original = this.labelTarget.textContent
    this.labelTarget.textContent = this.copiedLabelValue
    setTimeout(() => { this.labelTarget.textContent = original }, 2000)
  }

  // The async clipboard API only exists on secure origins; plain-http hosts need the old way.
  async write(text) {
    if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(text)

    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.style.position = "fixed"
    textarea.style.opacity = "0"
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand("copy")
    textarea.remove()
  }
}
