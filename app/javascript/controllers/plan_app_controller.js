import { Controller } from "@hotwired/stimulus"

// Mounts the Elm plan app (app/frontend/plan, built to plan.js). The bundle is
// only fetched on the plan page, and only once per visit.
export default class extends Controller {
  static values = { src: String, flags: Object }

  connect() {
    this.loadElm().then((Elm) => {
      if (!this.element.isConnected) return

      const node = document.createElement("div")
      this.element.replaceChildren(node)
      const app = Elm.Main.init({
        node,
        flags: { ...this.flagsValue, viewportWidth: window.innerWidth }
      })
      app.ports.replaceUrl.subscribe((url) => {
        window.history.replaceState(window.history.state, "", url)
      })
    })
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
