import { Controller } from "@hotwired/stimulus";
import { computePosition, autoUpdate } from "@floating-ui/dom";
import { ITEM_SELECTED } from "./combobox_item_controller";
import { ITEM_KEY_ESC } from "./combobox_content_controller";
import { NEW_ITEM_ADDED } from "./combobox_content_controller";

export const POPOVER_OPENED = "combobox#popoverOpened";

export default class extends Controller {
    static targets = ["input", "popover", "content", "search", "select"];

    static values = { closed: Boolean };

    constructor(...args) {
        super(...args);
        this.cleanup = undefined;
    }

    connect() {
        this.setFloatingElement();

        document.addEventListener(ITEM_SELECTED, (e) => this.itemSelected(e.detail), false);
        document.addEventListener(ITEM_KEY_ESC, () => this.toogleContent(), false);
        document.addEventListener(NEW_ITEM_ADDED, () => this.toogleContent(), false);
    }

    disconnect() {
        document.removeEventListener(ITEM_SELECTED, (e) => this.itemSelected(e.detail), false);
        document.removeEventListener(ITEM_KEY_ESC, () => this.toogleContent(), false);
        document.removeEventListener(NEW_ITEM_ADDED, () => this.toogleContent(), false);
        this.cleanup();
    }

    onClick() {
        this.toogleContent();
    }

    clickOutside(event) {
        if (this.closedValue) return;
        if (!event?.target) return;
        if (this.element.contains(event.target)) return;

        event.preventDefault();
        this.toogleContent();
    }

    itemSelected({ value, label, wrapperId }) {
        // ensuring we're pushing item to the right component i.e multiple use of this component within same view
        if(this.popoverTarget.dataset.wrapperId === wrapperId) {
            this.inputTarget.value = value;
            this.contentTarget.innerText = label;
            if (this.hasSelectTarget) this.selectTarget.value = value;
            this.toogleContent();
        }
    }

    toogleContent() {
        this.closedValue = !this.closedValue;

        this.popoverTarget.classList.toggle("invisible");
        this.inputTarget.setAttribute("aria-expanded", !this.closedValue);

        if (!this.closedValue) {
            const event = new CustomEvent(POPOVER_OPENED, { detail: { closed: this.closedValue } });
            document.dispatchEvent(event);
        }
    }

    setFloatingElement() {
        this.cleanup = autoUpdate(this.inputTarget, this.popoverTarget, () => {
            computePosition(this.inputTarget, this.popoverTarget).then(({ x, y }) => {
                Object.assign(this.popoverTarget.style, {
                    left: `${x}px`,
                    top: `${y}px`,
                });
            });
        });
    }
}
