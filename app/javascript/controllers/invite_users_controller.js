import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="invite-users"
export default class extends Controller {
  static targets = ["userTemplate", "emailInput", "emailInputError", "usersForm", "submitButton"];

  delimiterRegex = /[,;\t\r\v\f ]+/; // Allowed delimiters: comma, semicolon, tab variations and space
  emailListRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~@,;\t\r\v\f ]+$/; // All characters allowed in email addresses plus allowed delimiters
  
  connect() {
    this.toggleSubmitButtonVisibility();
    this.emailInputTarget.addEventListener('keydown', this.handleEnterKeyPress.bind(this));
    this.emailInputErrorTarget.classList.add('hidden');
  }

  disconnect() {
    this.emailInputTarget.removeEventListener('keydown', this.handleEnterKeyPress.bind(this));
  }

  handleEnterKeyPress(event) {
    if (event.key === 'Enter') {
      this.addEmailsToList(event);
    }
  }

  addEmailsToList(event) {
    event.preventDefault();

    if (!this.emailListRegex.test(this.emailInputTarget.value)) {
      this.emailInputErrorTarget.classList.remove('hidden');
      return;
    } else {
      this.emailInputErrorTarget.classList.add('hidden');
    }

    const emails = this.emailInputTarget.value.split(this.delimiterRegex).filter(email => email.length > 0);
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
