import { Controller } from "@hotwired/stimulus";
import { ITEM_SELECTED } from "./combobox_item_controller";

export const ITEM_ADDED_TO_LIST = "combobox-selected-items#added";
export const ITEM_REMOVED_TO_LIST = "combobox-selected-items#removed";

export default class extends Controller {
    static targets = ["newItemTemplate"];

    static values = { attribute: String };

    connect() {
        document.addEventListener(ITEM_SELECTED, (e) => this.itemSelected(e.detail), false);
    }

    disconnect() {
        document.removeEventListener(ITEM_SELECTED, (e) => this.itemSelected(e.detail), false);
    }

    itemSelected({ value, label, wrapperId }) {
        const newItem = this.newItemTemplateTarget.content.cloneNode(true);

        // ensuring we're pushing item to the right component i.e multiple use of this component within same view
        if(this.element.dataset.wrapperId === wrapperId) {
            const textElement = newItem.querySelector("span");
            const inputElement = newItem.querySelector("input[type='hidden']");
            const button = newItem.querySelector("button[type='button']");

            newItem.firstElementChild.dataset.value = value;
            textElement.innerHTML = label;
            inputElement.value = value;
            button.dataset.value = value;
            button.dataset.label = label;

            this.element.appendChild(newItem);

            const event = new CustomEvent(ITEM_ADDED_TO_LIST, { detail: { value, label } });
            document.dispatchEvent(event);
        }
    }

    removeItem(event) {
        const { value, label, wrapperId } = event.currentTarget.dataset;
        const target = this.element.querySelector(`[data-value="${value}"]`);
        target.remove();

        const newEvent = new CustomEvent(ITEM_REMOVED_TO_LIST, { detail: { value, label, wrapperId } });
        document.dispatchEvent(newEvent);
    }
};

