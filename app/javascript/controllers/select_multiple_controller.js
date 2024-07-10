import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="select-multiple"
export default class extends Controller {
  static targets = ['button', 'content', 'selectAllCheckbox', 'label'];
  static values = { label: String };

  connect() {
    this.buttonTarget.addEventListener('mousedown', this.preventDefault);
    this.buttonTarget.addEventListener('keydown', this.preventDefault);
    this.updateAllCheckbox();
  }

  disconnect() {
    this.buttonTarget.removeEventListener('mousedown', this.preventDefault);
    this.buttonTarget.removeEventListener('keydown', this.preventDefault);
  }

  toggleAll(event) {
    this.contentTarget.querySelectorAll('.value-checkbox').forEach((checkbox) => {
      checkbox.checked = event.target.checked;
    });
    this.updateLabel();
  }

  updateAllCheckbox(event) {
    this.selectAllCheckboxTarget.checked = this.#isAllChecked();
    this.updateLabel();
  }

  updateLabel() {
    let selectedValuesCount = this.contentTarget.querySelectorAll('.value-checkbox:checked').length;
    this.labelTarget.textContent = this.labelValue + ` (${selectedValuesCount})`;
  }

  #isAllChecked() {
    return Array.from(this.contentTarget.querySelectorAll('.value-checkbox')).every((checkbox) => checkbox.checked);
  }

  preventDefault(event) {
    event.preventDefault();
  }
}
