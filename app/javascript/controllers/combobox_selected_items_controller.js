import { Controller } from "@hotwired/stimulus";
import { ITEM_SELECTED } from "./combobox_item_controller";

export default class extends Controller {
    static targets = ["template"];

    static values = { attribute: String };

    connect() {
        document.addEventListener(ITEM_SELECTED, (e) => this.itemSelected(e.detail), false);
    }

    disconnect() {
        document.removeEventListener(ITEM_SELECTED, (e) => this.itemSelected(e.detail), false);
    }

    itemSelected({ value, label }) {
        // this.inputTarget.value = value;
        // this.selectTarget.value = value;
        // this.contentTarget.innerText = label;
        // this.toogleContent();
    }
};

