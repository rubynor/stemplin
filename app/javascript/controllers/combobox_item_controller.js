import { Controller } from "@hotwired/stimulus";
import { ITEM_KEY_UP, ITEM_KEY_DOWN, ITEM_KEY_ENTER } from "./combobox_content_controller";
import { ITEM_ADDED_TO_LIST } from "./combobox_selected_items_controller";

export const ITEM_SELECTED = "combobox-item#selected";
const ITEM_MOUSEENTER = "combobox-item#mouseenter";

export default class extends Controller {
    static targets = ["check"];

    connect() {
        document.addEventListener(ITEM_SELECTED, (e) => this.uncheck(e.detail), false);
        document.addEventListener(ITEM_MOUSEENTER, (e) => this.unselect(e.detail), false);
        document.addEventListener(ITEM_KEY_UP, (e) => this.handleKeyUp(e.detail), false);
        document.addEventListener(ITEM_KEY_DOWN, (e) => this.handleKeyDown(e.detail), false);
        document.addEventListener(ITEM_KEY_ENTER, (e) => this.handleKeyEnter(e.detail), false);
        document.addEventListener(ITEM_ADDED_TO_LIST, (e) => this.handleItemAddedToList(e.detail), false);
    }

    disconnect() {
        document.removeEventListener(ITEM_SELECTED, (e) => this.uncheck(e.detail), false);
        document.removeEventListener(ITEM_MOUSEENTER, (e) => this.unselect(e.detail), false);
        document.removeEventListener(ITEM_KEY_UP, (e) => this.handleKeyUp(e.detail), false);
        document.removeEventListener(ITEM_KEY_DOWN, (e) => this.handleKeyDown(e.detail), false);
        document.removeEventListener(ITEM_KEY_ENTER, (e) => this.handleKeyEnter(e.detail), false);
        document.removeEventListener(ITEM_ADDED_TO_LIST, (e) => this.handleItemAddedToList(e.detail), false);
    }

    mouseenter() {
        this.element.setAttribute("aria-selected", true);

        const { value } = this.element.dataset;
        const event = new CustomEvent(ITEM_MOUSEENTER, { detail: { value } });
        document.dispatchEvent(event);
    }

    selectItem() {
        this.checkTarget.classList.toggle("invisible", false);

        const { value, wrapperId } = this.element.dataset;
        const label = this.element.innerText;

        const event = new CustomEvent(ITEM_SELECTED, { detail: { value, label, wrapperId } });
        document.dispatchEvent(event);
    }

    handleKeyUp({ id }) {
        const [base, idx] = id.split("-");

        if (idx === "0") return;

        const prevIdx = parseInt(idx, 10) - 1;

        if (this.element.id === `${base}-${prevIdx}`) {
            this.element.setAttribute("aria-selected", true);
        } else {
            this.element.removeAttribute("aria-selected");
        }
    }

    handleKeyDown({ id, length }) {
        const [base, idx] = id.split("-");
        const nextIdx = parseInt(idx, 10) + 1;

        if (nextIdx === length) return;

        if (this.element.id === `${base}-${nextIdx}`) {
            this.element.setAttribute("aria-selected", true);
        } else {
            this.element.removeAttribute("aria-selected");
        }
    }

    handleKeyEnter({ id }) {
        if (this.element.id !== id) return;

        this.selectItem();
    }

    uncheck({ value }) {
        if (this.element.dataset.value !== value) {
            this.checkTarget.classList.toggle("invisible", true);
        }
    }

    unselect({ value }) {
        if (this.element.dataset.value !== value) {
            this.element.removeAttribute("aria-selected");
        }
    }

    handleItemAddedToList({ value, label }) {
        if (this.element.dataset.value === value) {
            this.element.remove();
        }
    }
}
