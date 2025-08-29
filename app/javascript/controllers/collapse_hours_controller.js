import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapse-hours"

export default class extends Controller {
  connect() {
    let collapsibles = document.getElementsByClassName('collapsible');
  
    // toggle hidden on every task collapse div in a project
    for(let i = 0; i < collapsibles.length; i++){
      let button = collapsibles[i];
      let collapsibleId = "collapsible-" + button.dataset.taskId;
      let collapsible = document.getElementById(collapsibleId)
  
      button.addEventListener('click', () => {
          collapsible.classList.toggle('hidden');
      });
    }  
  }
}
