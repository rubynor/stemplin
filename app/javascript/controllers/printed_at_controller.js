import { Controller } from "@hotwired/stimulus"

// Stamps the moment of printing (not page load) on the printed report.
export default class extends Controller {
    static targets = ["label"]

    connect() {
        this.stamp = this.stamp.bind(this)
        window.addEventListener("beforeprint", this.stamp)
    }

    disconnect() {
        window.removeEventListener("beforeprint", this.stamp)
    }

    stamp() {
        const now = new Date()
        const pad = (n) => String(n).padStart(2, "0")
        const time = `${pad(now.getDate())}.${pad(now.getMonth() + 1)}.${now.getFullYear()} ${pad(now.getHours())}:${pad(now.getMinutes())}`
        this.labelTarget.textContent = this.labelTarget.dataset.template.replace("%{time}", time)
    }
}
