import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    setValue(value) {
        this.element.value = value;

    //     trying to mimic phlex ui input controller that is passed as an outlet;
    }
}
