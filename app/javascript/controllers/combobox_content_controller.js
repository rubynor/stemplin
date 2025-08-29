import { Controller } from "@hotwired/stimulus";
import { ITEM_REMOVED_TO_LIST } from "./combobox_selected_items_controller";

const POPOVER_OPENED = "combobox#popoverOpened";

export const ITEM_KEY_UP = "combobox-content#keyUp";
export const ITEM_KEY_DOWN = "combobox-content#keyDown";
export const ITEM_KEY_ENTER = "combobox-content#keyEnter";
export const ITEM_KEY_ESC = "combobox-content#keyEsc";

export const NEW_ITEM_ADDED = "combobox-newItem#added";

export default class extends Controller {
    static targets = ["list", "item", "empty", "group", "search", "optionTemplate"];

    connect() {
        document.addEventListener(POPOVER_OPENED, (event) => this.handlePopoverToggle(event), false);
        document.addEventListener(ITEM_REMOVED_TO_LIST, (e) => this.handleOptionRemovedFromList(e.detail), false);
        this.generateItemsIds();
    }

    disconnect() {
        document.removeEventListener(POPOVER_OPENED, (event) => this.handlePopoverToggle(event), false);
        document.removeEventListener(ITEM_REMOVED_TO_LIST, (e) => this.handleOptionRemovedFromList(e.detail), false);
    }

    handlePopoverToggle(event) {
        const { closed } = event.detail;
        this.searchTarget.value = "";
        if (!closed) {
            this.searchTarget.focus();
            this.toggleVisibility(this.itemTargets, true);
            this.toggleVisibility(this.groupTargets, true);
            this.toggleVisibility(this.emptyTargets, false);
        }
    }

    handleKeyUp() {
        const id = this.getSelectedItemId();

        const event = new CustomEvent(ITEM_KEY_UP, { detail: { id } });
        document.dispatchEvent(event);
    }

    handleKeyDown() {
        const id = this.getSelectedItemId();
        const { length } = this.itemTargets;

        const event = new CustomEvent(ITEM_KEY_DOWN, { detail: { id, length } });
        document.dispatchEvent(event);
    }

    handleKeyEnter() {
        const id = this.getSelectedItemId();

        const event = new CustomEvent(ITEM_KEY_ENTER, { detail: { id } });
        document.dispatchEvent(event);
    }

    handleKeyEsc() {
        document.dispatchEvent(new CustomEvent(ITEM_KEY_ESC));
    }

    filter(event) {
        const query = this.sanitizeStr(event.target.value);

        this.toggleVisibility(this.itemTargets, false);

        const visibleItems = this.filterItems(query);
        this.toggleVisibility(visibleItems, true);

        this.toggleVisibility(this.emptyTargets, visibleItems.length === 0);

        this.updateGroupVisibility();
    }

    updateGroupVisibility() {
        this.groupTargets.forEach((group) => {
            const hasVisibleItems =
                group.querySelectorAll("[data-combobox-content-target='item']:not(.hidden)").length > 0;
            this.toggleVisibility([group], hasVisibleItems);
        });
    }

    generateItemsIds() {
        const listId = this.listTarget.getAttribute("id");
        this.itemTargets.forEach((item, index) => {
            if (index === 0) item.setAttribute("aria-selected", "true");

            item.id = `${listId}-${index}`;
        });
    }

    filterItems(query) {
        return this.itemTargets.filter((item) => this.sanitizeStr(item.innerText).includes(query));
    }

    toggleVisibility(elements, isVisible) {
        elements.forEach((el) => el.classList.toggle("hidden", !isVisible));
    }

    sanitizeStr(str) {
        return str.toLowerCase().trim();
    }

    getSelectedItemId() {
        const selectedItem = this.itemTargets.find((item) => item.getAttribute("aria-selected") === "true");
        return selectedItem.getAttribute("id");
    }

    handleOptionRemovedFromList({ value, label, wrapperId }) {
        if(this.element.dataset.wrapperId === wrapperId) {
            const newOption = this.optionTemplateTarget.content.cloneNode(true);
            const textElement = newOption.querySelector("span");

            newOption.firstElementChild.dataset.value = value;
            textElement.innerHTML = label;

            this.listTarget.appendChild(newOption);
        }
    }

    addItem() {
        const { value, dataset: { wrapperId } } = this.searchTarget;

        const event = new CustomEvent(NEW_ITEM_ADDED, { detail: { value, label: value, wrapperId } });
        document.dispatchEvent(event);
    }
}
