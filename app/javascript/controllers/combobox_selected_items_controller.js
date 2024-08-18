import { Controller } from "@hotwired/stimulus";
import { ITEM_SELECTED } from "./combobox_item_controller";
import { NEW_ITEM_ADDED } from "./combobox_content_controller";

export const ITEM_ADDED_TO_LIST = "combobox-selected-items#added";
export const ITEM_REMOVED_TO_LIST = "combobox-selected-items#removed";

const itemsType = Object.freeze(({
    NEW: "new-item-added",
    SELECTED: "item-selected-from-the-list"
}))

export default class extends Controller {
    static targets = ["newItemTemplate"];

    static values = { attribute: String };

    connect() {
        // different event name due to `ITEM_SELECTED` being used for different purposes and we do not want a newly added item to behave as a selected from the list item.
        document.addEventListener(ITEM_SELECTED, (e) => this.itemSelected(e.detail), false);
        document.addEventListener(NEW_ITEM_ADDED, (e) => this.itemSelected(e.detail, itemsType.NEW), false);
    }

    disconnect() {
        document.removeEventListener(ITEM_SELECTED, (e) => this.itemSelected(e.detail), false);
        document.removeEventListener(NEW_ITEM_ADDED, (e) => this.itemSelected(e.detail, itemsType.NEW), false);
    }

    itemSelected({ value, label, wrapperId }, itemType = itemsType.SELECTED) {
        const newItem = this.newItemTemplateTarget.content.cloneNode(true);

        // ensuring we're pushing item to the right component i.e multiple use of this component within same view
        if(this.element.dataset.wrapperId === wrapperId) {
            const textElement = newItem.querySelector("span");
            const inputElement = newItem.querySelector("input[type='hidden']");
            const button = newItem.querySelector("button[type='button']");

            newItem.firstElementChild.dataset.value = value;
            textElement.innerHTML = label;
            inputElement.value = value;
            Object.assign(button.dataset, { value, label, itemType });

            this.element.appendChild(newItem);

            const event = new CustomEvent(ITEM_ADDED_TO_LIST, { detail: { value, label } });
            document.dispatchEvent(event);
        }
    }

    removeItem(event) {
        const { value, label, wrapperId, itemType } = event.currentTarget.dataset;
        const target = this.element.querySelector(`[data-value="${value}"]`);
        target.remove();

        // Event will be triggered only for items that were already in the input select options
        if(typeof itemType === "undefined" || itemType === itemsType.SELECTED) {
            const newEvent = new CustomEvent(ITEM_REMOVED_TO_LIST, { detail: { value, label, wrapperId } });
            document.dispatchEvent(newEvent);
        }
    }
};

