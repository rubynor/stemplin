import { Controller } from "@hotwired/stimulus"
import { computePosition, autoUpdate, offset, flip, size } from "@floating-ui/dom"

const CHEVRON = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-4 w-4 shrink-0 text-muted-foreground" aria-hidden="true"><path d="m6 9 6 6 6-6"/></svg>`
const CHECK = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="h-4 w-4 shrink-0 text-primary-600 invisible" data-check aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>`

// Inline so it wins over whatever sizing classes the select carries.
const HIDDEN_SELECT_STYLE = "position:absolute;width:1px;height:1px;min-width:0;margin:0;padding:0;border:0;opacity:0;pointer-events:none;"
const TRIGGER_CLASSES = "form-input flex items-center justify-between gap-x-2 text-left cursor-pointer data-[focus]:border-primary data-[focus]:ring-2 data-[focus]:ring-ring/25 data-[invalid]:border-destructive-foreground"
const POPOVER_CLASSES = "fixed left-0 top-0 z-[70] hidden flex-col rounded-xl border border-border bg-background p-1 text-foreground shadow-pop outline-none"
const SEARCH_CLASSES = "mb-1 w-full rounded-lg border border-input bg-background px-2.5 py-1.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:border-primary focus:ring-2 focus:ring-ring/25"
const LIST_CLASSES = "min-h-0 flex-1 overflow-y-auto overscroll-contain"
const GROUP_CLASSES = "px-2 pt-2 pb-1 text-xs font-semibold uppercase tracking-wide text-muted-foreground"
const OPTION_CLASSES = "flex cursor-pointer select-none items-center justify-between gap-x-2 rounded-md px-2 py-1.5 text-sm text-foreground data-[active]:bg-accent aria-selected:font-medium aria-disabled:cursor-not-allowed aria-disabled:opacity-50"
const EMPTY_CLASSES = "px-2 py-3 text-center text-sm text-muted-foreground"

let nextId = 0

// Connects to data-controller="custom-select" on a native <select>.
//
// The native element stays in the DOM as the source of truth: it is what the
// form submits, what the browser validates, and what other controllers read
// and listen to. This controller hides it and draws a trigger button and a
// listbox from its options, writing every choice back and dispatching the
// same input/change events a user interaction would.
export default class extends Controller {
  static values = {
    searchPlaceholder: { type: String, default: "Search…" },
    emptyText: { type: String, default: "No results" },
    // The search field appears once the list is too long to scan.
    searchThreshold: { type: Number, default: 10 },
  }

  connect() {
    this.uid = `custom-select-${nextId++}`
    this.items = []
    this.activeIndex = -1
    this.typeahead = ""

    this.build()
    this.syncTrigger()

    this.onSelectChange = () => this.syncTrigger()
    this.onSelectFocus = () => this.handleSelectFocus()
    this.onSelectBlur = () => delete this.trigger.dataset.focus
    this.onInvalid = () => {
      this.invalidFocus = true
      this.trigger.dataset.invalid = ""
    }
    this.onFormReset = () => setTimeout(() => this.syncTrigger())
    this.onOutsidePointer = (event) => {
      if (!this.trigger.contains(event.target) && !this.popover.contains(event.target)) this.close()
    }

    this.element.addEventListener("change", this.onSelectChange)
    this.element.addEventListener("focus", this.onSelectFocus)
    this.element.addEventListener("blur", this.onSelectBlur)
    this.element.addEventListener("invalid", this.onInvalid)
    this.element.form?.addEventListener("reset", this.onFormReset)

    // Options can be swapped from outside (e.g. tasks reloaded per project),
    // and the select can be enabled or disabled after the fact.
    this.observer = new MutationObserver(() => {
      this.syncTrigger()
      if (this.isOpen) this.renderOptions()
    })
    this.observer.observe(this.element, { childList: true, subtree: true, attributes: true, attributeFilter: ["disabled"] })
  }

  disconnect() {
    this.close()
    this.observer?.disconnect()
    this.element.removeEventListener("change", this.onSelectChange)
    this.element.removeEventListener("focus", this.onSelectFocus)
    this.element.removeEventListener("blur", this.onSelectBlur)
    this.element.removeEventListener("invalid", this.onInvalid)
    this.element.form?.removeEventListener("reset", this.onFormReset)
    this.trigger?.remove()
    this.popover?.remove()
    this.element.style.cssText = this.originalStyle || ""
    this.element.removeAttribute("tabindex")
    this.element.removeAttribute("aria-hidden")
  }

  // ----- DOM -----

  build() {
    // A copy left behind by a cached or cloned page would otherwise be doubled.
    const leftover = this.element.nextElementSibling
    if (leftover?.hasAttribute("data-custom-select-trigger")) leftover.remove()

    // Absolutely positioned with no offsets, the select keeps its place in the
    // layout, so the browser's validation bubble still points at the field.
    this.originalStyle = this.element.style.cssText
    this.element.style.cssText += HIDDEN_SELECT_STYLE
    this.element.setAttribute("tabindex", "-1")
    this.element.setAttribute("aria-hidden", "true")

    this.trigger = document.createElement("button")
    this.trigger.type = "button"
    this.trigger.className = TRIGGER_CLASSES
    this.trigger.setAttribute("data-custom-select-trigger", "")
    if (this.element.id) this.trigger.setAttribute("data-custom-select-for", this.element.id)
    this.trigger.setAttribute("role", "combobox")
    this.trigger.setAttribute("aria-haspopup", "listbox")
    this.trigger.setAttribute("aria-expanded", "false")
    this.trigger.setAttribute("aria-controls", `${this.uid}-list`)
    const labelledBy = this.labelId()
    if (labelledBy) this.trigger.setAttribute("aria-labelledby", `${labelledBy} ${this.uid}-value`)
    this.trigger.innerHTML = `<span id="${this.uid}-value" class="min-w-0 flex-1 truncate" data-value></span>${CHEVRON}`
    this.valueLabel = this.trigger.querySelector("[data-value]")
    this.trigger.addEventListener("click", () => this.toggle())
    this.trigger.addEventListener("keydown", (event) => this.onKeydown(event))
    this.element.insertAdjacentElement("afterend", this.trigger)

    // The list lives on <body> so a dialog's overflow can never clip it.
    this.popover = document.createElement("div")
    this.popover.className = POPOVER_CLASSES
    this.popover.setAttribute("data-custom-select-popover", "")
    if (this.element.id) this.popover.setAttribute("data-custom-select-for", this.element.id)

    this.search = document.createElement("input")
    this.search.type = "text"
    this.search.className = SEARCH_CLASSES
    this.search.placeholder = this.searchPlaceholderValue
    this.search.setAttribute("aria-label", this.searchPlaceholderValue)
    this.search.setAttribute("aria-controls", `${this.uid}-list`)
    this.search.autocomplete = "off"
    this.search.addEventListener("input", () => this.renderOptions())
    this.search.addEventListener("keydown", (event) => this.onKeydown(event))

    this.list = document.createElement("div")
    this.list.id = `${this.uid}-list`
    this.list.className = LIST_CLASSES
    this.list.setAttribute("role", "listbox")
    this.list.addEventListener("click", (event) => {
      const item = event.target.closest("[role=option]")
      if (item) this.choose(Number(item.dataset.index))
    })
    this.list.addEventListener("mousemove", (event) => {
      const item = event.target.closest("[role=option]")
      if (item) this.setActive(Number(item.dataset.index), { scroll: false })
    })

    this.popover.append(this.search, this.list)
  }

  labelId() {
    const label = this.element.labels?.[0]
    if (!label) return null
    if (!label.id) label.id = `${this.uid}-label`
    return label.id
  }

  // Options without a value are prompts: shown as the placeholder, not listed.
  choices() {
    return Array.from(this.element.options).filter((option) => option.value !== "")
  }

  syncTrigger() {
    if (!this.trigger) return
    const selected = this.element.selectedOptions[0]
    const isPlaceholder = !selected || selected.value === ""
    // A non-breaking space keeps the button's height when there is no text.
    this.valueLabel.textContent = selected?.text.trim() || " "
    this.valueLabel.classList.toggle("text-muted-foreground", isPlaceholder)
    this.trigger.disabled = this.element.disabled
    if (this.element.disabled) this.close()
    if (!isPlaceholder) delete this.trigger.dataset.invalid
  }

  renderOptions() {
    const query = this.search.value.trim().toLowerCase()
    const selected = this.element.selectedOptions[0]
    this.list.replaceChildren()
    this.items = []
    let currentGroup = null

    this.choices().forEach((option) => {
      if (query && !option.text.toLowerCase().includes(query)) return

      const group = option.parentElement.tagName === "OPTGROUP" ? option.parentElement : null
      if (group && group !== currentGroup) {
        const heading = document.createElement("div")
        heading.className = GROUP_CLASSES
        heading.setAttribute("role", "presentation")
        heading.textContent = group.label
        this.list.append(heading)
      }
      currentGroup = group

      const index = this.items.length
      const disabled = option.disabled || !!group?.disabled
      const item = document.createElement("div")
      item.id = `${this.uid}-option-${index}`
      item.className = OPTION_CLASSES
      item.setAttribute("role", "option")
      item.setAttribute("aria-selected", String(option === selected))
      if (disabled) item.setAttribute("aria-disabled", "true")
      item.dataset.index = index
      item.dataset.value = option.value
      item.innerHTML = `<span class="min-w-0 flex-1 truncate"></span>${CHECK}`
      item.firstElementChild.textContent = option.text
      if (option === selected) item.querySelector("[data-check]").classList.remove("invisible")
      this.list.append(item)
      this.items.push({ option, item, disabled })
    })

    if (this.items.length === 0) {
      const empty = document.createElement("div")
      empty.className = EMPTY_CLASSES
      empty.textContent = this.emptyTextValue
      this.list.append(empty)
    }

    const selectedIndex = this.items.findIndex(({ option }) => option === selected)
    this.setActive(selectedIndex >= 0 ? selectedIndex : this.nextEnabled(-1, 1))
  }

  // ----- Open / close -----

  get isOpen() {
    return !!this.popover && !this.popover.classList.contains("hidden")
  }

  toggle() {
    this.isOpen ? this.close() : this.open()
  }

  open() {
    if (this.isOpen || this.element.disabled) return

    const searchable = this.choices().length > this.searchThresholdValue
    this.search.value = ""
    this.search.classList.toggle("hidden", !searchable)

    document.body.append(this.popover)
    this.popover.classList.remove("hidden")
    this.popover.classList.add("flex")
    this.trigger.setAttribute("aria-expanded", "true")
    this.renderOptions()

    this.stopAutoUpdate = autoUpdate(this.trigger, this.popover, () => this.position())
    document.addEventListener("pointerdown", this.onOutsidePointer, true)
    if (searchable) this.search.focus()
  }

  close({ focusTrigger = false } = {}) {
    if (!this.isOpen) return
    this.stopAutoUpdate?.()
    document.removeEventListener("pointerdown", this.onOutsidePointer, true)
    this.popover.classList.add("hidden")
    this.popover.classList.remove("flex")
    this.popover.remove()
    this.trigger.setAttribute("aria-expanded", "false")
    this.trigger.removeAttribute("aria-activedescendant")
    this.search.removeAttribute("aria-activedescendant")
    if (focusTrigger) this.trigger.focus()
  }

  position() {
    // Prefer opening downward and scrolling; flip up only when there is
    // too little room below to show a usable list.
    const roomBelow = window.innerHeight - this.trigger.getBoundingClientRect().bottom - 12
    computePosition(this.trigger, this.popover, {
      strategy: "fixed",
      placement: "bottom-start",
      middleware: [
        offset(4),
        ...(roomBelow < 200 ? [flip({ padding: 8 })] : []),
        size({
          padding: 8,
          apply: ({ rects, availableHeight, elements }) => {
            Object.assign(elements.floating.style, {
              width: `${rects.reference.width}px`,
              maxHeight: `${Math.max(120, Math.min(availableHeight, 320))}px`,
            })
          },
        }),
      ],
    }).then(({ x, y }) => {
      Object.assign(this.popover.style, { transform: `translate(${Math.round(x)}px, ${Math.round(y)}px)` })
    })
  }

  // ----- Selection -----

  choose(index) {
    const entry = this.items[index]
    if (!entry || entry.disabled) return

    const changed = this.element.value !== entry.option.value
    this.element.value = entry.option.value
    this.close({ focusTrigger: true })
    this.syncTrigger()
    if (changed) {
      this.element.dispatchEvent(new Event("input", { bubbles: true }))
      this.element.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }

  setActive(index, { scroll = true } = {}) {
    this.items[this.activeIndex]?.item.removeAttribute("data-active")
    this.activeIndex = index
    const entry = this.items[index]
    const focused = this.search.classList.contains("hidden") ? this.trigger : this.search
    if (!entry) {
      focused.removeAttribute("aria-activedescendant")
      return
    }
    entry.item.setAttribute("data-active", "")
    focused.setAttribute("aria-activedescendant", entry.item.id)
    if (scroll) entry.item.scrollIntoView({ block: "nearest" })
  }

  // The next selectable index from `from` in `direction`, or `from` if none.
  nextEnabled(from, direction) {
    for (let index = from + direction; index >= 0 && index < this.items.length; index += direction) {
      if (!this.items[index].disabled) return index
    }
    return from
  }

  // ----- Keyboard -----

  onKeydown(event) {
    if (!this.isOpen) {
      if (["ArrowDown", "ArrowUp", "Enter", " "].includes(event.key)) {
        event.preventDefault()
        this.open()
      } else if (this.isPrintable(event)) {
        this.open()
        // With a search field the keystroke lands there; otherwise jump to a match.
        if (this.search.classList.contains("hidden")) this.jumpTo(event.key)
      }
      return
    }

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.setActive(this.nextEnabled(this.activeIndex, 1))
        break
      case "ArrowUp":
        event.preventDefault()
        this.setActive(this.nextEnabled(this.activeIndex, -1))
        break
      case "Home":
        if (event.target === this.search) break
        event.preventDefault()
        this.setActive(this.nextEnabled(-1, 1))
        break
      case "End":
        if (event.target === this.search) break
        event.preventDefault()
        this.setActive(this.nextEnabled(this.items.length, -1))
        break
      case "Enter":
        event.preventDefault()
        this.choose(this.activeIndex)
        break
      case " ":
        if (event.target === this.search) break
        event.preventDefault()
        this.choose(this.activeIndex)
        break
      case "Escape":
        // Only the list closes; a surrounding dialog stays open.
        event.preventDefault()
        event.stopPropagation()
        this.close({ focusTrigger: true })
        break
      case "Tab":
        this.close({ focusTrigger: event.target === this.search })
        break
      default:
        if (event.target !== this.search && this.isPrintable(event)) this.jumpTo(event.key)
    }
  }

  isPrintable(event) {
    return event.key.length === 1 && event.key !== " " && !event.ctrlKey && !event.metaKey && !event.altKey
  }

  // Type-to-select for short lists, like a native select.
  jumpTo(character) {
    clearTimeout(this.typeaheadTimer)
    this.typeahead += character.toLowerCase()
    this.typeaheadTimer = setTimeout(() => { this.typeahead = "" }, 600)

    const match = this.items.findIndex(({ option, disabled }) => !disabled && option.text.trim().toLowerCase().startsWith(this.typeahead))
    if (match >= 0) this.setActive(match)
  }

  // Focus reaches the hidden select from its <label> or from form validation.
  // Validation must keep it there, or the browser's message disappears.
  handleSelectFocus() {
    if (this.invalidFocus) {
      this.invalidFocus = false
      this.trigger.dataset.focus = ""
    } else {
      this.trigger.focus()
    }
  }
}
