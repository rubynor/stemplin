import { Controller } from "@hotwired/stimulus"

// Mounts the Elm plan app (app/frontend/plan, built to plan.js). The bundle is
// only fetched on the plan page, and only once per visit.
export default class extends Controller {
  static values = { src: String, flags: Object }

  connect() {
    this.replaceUrl = (url) => window.history.replaceState(window.history.state, "", url)
    this.skipMorph = this.skipMorph.bind(this)
    document.addEventListener("turbo:before-morph-element", this.skipMorph)
    this.mount()
  }

  disconnect() {
    document.removeEventListener("turbo:before-morph-element", this.skipMorph)
    this.unmount()
  }

  // Elm owns everything inside this element. A morphing page refresh (e.g. the
  // redirect back after switching language) must leave it alone, or Elm ends up
  // patching nodes that are gone. Take the new flags and start over instead.
  skipMorph(event) {
    if (event.target !== this.element) return

    event.preventDefault()
    const flags = `data-${this.identifier}-flags-value`
    this.element.setAttribute(flags, event.detail.newElement.getAttribute(flags))
    this.mount()
  }

  mount() {
    this.unmount()
    const mounting = (this.mounting = {})

    this.loadElm().then((Elm) => {
      if (this.mounting !== mounting || !this.element.isConnected) return

      const node = document.createElement("div")
      this.element.replaceChildren(node)
      this.app = Elm.Main.init({
        node,
        flags: { ...this.flagsValue, viewportWidth: window.innerWidth }
      })
      this.app.ports.replaceUrl.subscribe(this.replaceUrl)
    })
  }

  // Elm apps cannot be destroyed, so tell the old one to stop listening instead.
  unmount() {
    this.mounting = null
    if (!this.app) return

    this.app.ports.replaceUrl.unsubscribe(this.replaceUrl)
    this.app.ports.stop.send(null)
    this.app = null
  }

  loadElm() {
    if (window.Elm) return Promise.resolve(window.Elm)

    window.planElmLoading ||= new Promise((resolve, reject) => {
      const script = document.createElement("script")
      script.src = this.srcValue
      script.onload = () => resolve(window.Elm)
      script.onerror = reject
      document.head.appendChild(script)
    })
    return window.planElmLoading
  }
}
