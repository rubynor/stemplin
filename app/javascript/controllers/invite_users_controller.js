import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="invite-users"
export default class extends Controller {
  static targets = ["userTemplate", "emailInput", "usersForm", "submitButton"];

  connect() {
    this.toggleSubmitButtonVisibility();
  }

  addEmailsToList(event) {
    event.preventDefault();

    const emails = this.emailInputTarget.value.split(/[,\n; ]+/).filter(email => email.length > 0);
    emails.forEach(email => this.#addEmailToList(email));

    this.emailInputTarget.value = '';
    this.emailInputTarget.focus();
    this.toggleSubmitButtonVisibility();
  }

  #addEmailToList(email) {
    const newIndex = Math.floor(Math.random() * 1000000000);

    const userContent = this.userTemplateTarget.content.cloneNode(true);
    userContent.querySelectorAll('input.email-input').forEach((input) => input.setAttribute('value', email));
    let userHTML = userContent.firstElementChild.outerHTML;
    userHTML = userHTML.replace(/NEW_INDEX/g, newIndex);

    this.usersFormTarget.insertAdjacentHTML('beforeend', userHTML);
  }

  removeFromList(event) {
    event.preventDefault();
    event.target.closest('.user-fields').remove();
    this.toggleSubmitButtonVisibility();
  }

  toggleSubmitButtonVisibility() {
    if (this.usersFormTarget.querySelectorAll('.user-fields').length > 0) {
      this.submitButtonTarget.classList.remove('hidden');
    } else {
      this.submitButtonTarget.classList.add('hidden');
    }
  }
}
