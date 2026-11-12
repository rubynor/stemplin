import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="section-nav"
// A list of links to the sections of a long page. Marks the link of the section
// being read while the page scrolls, and scrolls to a section when its link is
// clicked. Each link's href is the id of its section ("#some_id").
export default class extends Controller {
  static targets = ["link", "list"]
  static classes = ["active", "inactive"]

  connect() {
    this.update = this.update.bind(this)
    window.addEventListener("scroll", this.update, { passive: true })
    window.addEventListener("resize", this.update, { passive: true })
    this.update()
  }

  disconnect() {
    window.removeEventListener("scroll", this.update)
    window.removeEventListener("resize", this.update)
  }

  jump(event) {
    const section = this.sectionFor(event.currentTarget)
    if (!section) return

    event.preventDefault()
    const calm = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    section.scrollIntoView({ behavior: calm ? "auto" : "smooth", block: "start" })
    history.replaceState(null, "", event.currentTarget.hash)
  }

  update() {
    const current = this.currentLink()

    this.linkTargets.forEach((link) => {
      const active = link === current
      this.activeClasses.forEach((name) => link.classList.toggle(name, active))
      this.inactiveClasses.forEach((name) => link.classList.toggle(name, !active))
      if (active) link.setAttribute("aria-current", "location")
      else link.removeAttribute("aria-current")
    })

    if (current) this.reveal(current)
    this.fade()
  }

  // Tells the list whether links are hidden past its right edge, so it can
  // fade that edge out as a hint that it scrolls.
  fade() {
    if (!this.hasListTarget) return

    const list = this.listTarget
    list.dataset.more = list.scrollLeft + list.clientWidth < list.scrollWidth - 1
  }

  // The last section whose top has passed the reading line, just below
  // whatever is stuck to the top of the window. At the very bottom of the page
  // it is the last section, which may be too short to ever reach that line.
  currentLink() {
    const links = this.linkTargets.filter((link) => this.sectionFor(link))
    if (links.length === 0) return null

    const atBottom = window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2
    if (atBottom && window.scrollY > 0) return links[links.length - 1]

    const first = this.sectionFor(links[0])
    const line = parseFloat(getComputedStyle(first).scrollMarginTop) + 8
    const passed = links.filter((link) => this.sectionFor(link).getBoundingClientRect().top <= line)
    return passed[passed.length - 1] || links[0]
  }

  // On small screens the list scrolls sideways; keep the marked link in view
  // without moving the page itself.
  reveal(link) {
    if (!this.hasListTarget) return

    const list = this.listTarget
    if (list.scrollWidth <= list.clientWidth) return

    const left = link.offsetLeft - list.offsetLeft
    const right = left + link.offsetWidth
    if (left < list.scrollLeft) list.scrollLeft = left
    else if (right > list.scrollLeft + list.clientWidth) list.scrollLeft = right - list.clientWidth
  }

  sectionFor(link) {
    return document.getElementById(link.hash.slice(1))
  }
}
