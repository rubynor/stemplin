import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="grouped-select-multiple"
export default class extends Controller {
  static targets = ['button', 'content', 'selectAllCheckbox', 'label'];
  static values = { label: String };

  initialize() {
    document.addEventListener('turbo:morph', () => { this.disconnect(); this.connect(); });
  }

  connect() {
    this.buttonTarget.addEventListener('mousedown', this.preventDefault);
    this.buttonTarget.addEventListener('keydown', this.preventDefault);
    this.updateAllAndGroupCheckboxes();
  }

  disconnect() {
    this.buttonTarget.removeEventListener('mousedown', this.preventDefault);
    this.buttonTarget.removeEventListener('keydown', this.preventDefault);
  }

  toggleAll(event) {
    this.contentTarget.querySelectorAll('input[type="checkbox"]').forEach((checkbox) => {
      checkbox.checked = event.target.checked;
    });
    this.updateLabel();
  }

  toggleGroup(event) {
    let group = event.target.closest('.group-div');
    group.querySelectorAll('.value-checkbox').forEach((checkbox) => {
      checkbox.checked = event.target.checked;
    });
    this.selectAllCheckboxTarget.checked = this.#isAllChecked();
    this.updateLabel();
  }

  updateAllAndGroupCheckboxes(event = null) {
    const groups = event ? [event.target.closest('.group-div')] : this.contentTarget.querySelectorAll('.group-div');
    groups.forEach((group) => {
      console.log(group.querySelector('.group-checkbox'));
      group.querySelector('.group-checkbox').checked = this.#isGroupChecked(group);
    });
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

  #isGroupChecked(group) {
    return Array.from(group.querySelectorAll('.value-checkbox')).every((checkbox) => checkbox.checked);
  }

  preventDefault(event) {
    event.preventDefault();
  }
}
