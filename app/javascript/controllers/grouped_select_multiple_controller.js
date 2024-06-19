import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="grouped-select-multiple"
export default class extends Controller {
  static targets = ['button', 'content', 'selectAllCheckbox'];

  connect() {
    this.buttonTarget.addEventListener('mousedown', this.preventDefault);
    this.buttonTarget.addEventListener('keydown', this.preventDefault);
  }

  disconnect() {
    this.buttonTarget.removeEventListener('mousedown', this.preventDefault);
    this.buttonTarget.removeEventListener('keydown', this.preventDefault);
  }

  toggleAll(event) {
    this.contentTarget.querySelectorAll('input[type="checkbox"]').forEach((checkbox) => {
      checkbox.checked = event.target.checked;
    } );
  }

  toggleGroup(event) {
    let group = event.target.closest('.group-div');
    group.querySelectorAll('.value-checkbox').forEach((checkbox) => {
      checkbox.checked = event.target.checked;
    });
    this.selectAllCheckboxTarget.checked = this.#isAllChecked();
  }

  updateAllAndGroupCheckboxes(event) {
    let group = event.target.closest('.group-div');
    group.querySelector('.group-checkbox').checked = this.#isGroupChecked(group);
    this.selectAllCheckboxTarget.checked = this.#isAllChecked();
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
