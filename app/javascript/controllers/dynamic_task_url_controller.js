import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dynamic-task-url"
export default class extends Controller {
  static targets = ["link", "taskIdInput"];


  connect() {
    this.setTakenTaskIds();
    this.linkTarget.addEventListener("click", this.setTakenTaskIds.bind(this));
  }

  disconnect() {
    this.linkTarget.removeEventListener("click", this.setTakenTaskIds.bind(this));
  }

  setTakenTaskIds() {
    const url = new URL(this.linkTarget.href);
    const takenTaskIds = this.taskIdInputTargets.map((input) => input.value);

    url.searchParams.set('taken_task_ids', JSON.stringify(takenTaskIds));
    this.linkTarget.href = url.toString();
  }
}
