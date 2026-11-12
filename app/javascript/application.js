// Entry point for the build script in your package.json
import "@hotwired/turbo-rails";
import "phlex_ui";
import "./controllers";
import "./src/jquery";
import "./custom/companion";

import { Application } from "@hotwired/stimulus";
import { StreamActions } from "@hotwired/turbo";

const application = Application.start();


StreamActions.remove_modal = function() {
  const target = this.getAttribute("target");

  const elementToRemove = document.getElementById(target);
  if (elementToRemove) {
    const specificDialog = elementToRemove.closest('div[data-controller="ruby-ui--dialog"]');

    elementToRemove.remove();

    if (specificDialog) {
      specificDialog.remove();
    }

    document?.body?.classList?.remove("overflow-hidden");
  }
}
// Confirm messages carry names people typed in (projects, clients, members),
// so they are never inserted as HTML. Only the emphasis the messages use is
// kept: <span>, <b> and <strong>, with nothing but a class attribute.
const CONFIRM_EMPHASIS_TAGS = ["SPAN", "B", "STRONG"];

const safeConfirmNodes = (source) => {
  const fragment = document.createDocumentFragment();

  source.childNodes.forEach((node) => {
    if (node.nodeType === Node.TEXT_NODE) {
      fragment.appendChild(document.createTextNode(node.textContent));
    } else if (node.nodeType === Node.ELEMENT_NODE && CONFIRM_EMPHASIS_TAGS.includes(node.tagName)) {
      const element = document.createElement(node.tagName.toLowerCase());
      if (node.hasAttribute("class")) element.className = node.getAttribute("class");
      element.appendChild(safeConfirmNodes(node));
      fragment.appendChild(element);
    } else {
      // Anything else is shown as the text it was written as.
      fragment.appendChild(document.createTextNode(node.outerHTML ?? node.textContent ?? ""));
    }
  });

  return fragment;
};

Turbo.config.forms.confirm = (message, element) => {
  const dialog = document.getElementById("turbo-confirm-dialog");

  // Parsed into an inert document: nothing in it runs or loads.
  const parsed = new DOMParser().parseFromString(message ?? "", "text/html");
  dialog.querySelector("p").replaceChildren(safeConfirmNodes(parsed.body));
  dialog.showModal();
  document?.body?.classList.add('overflow-hidden');

  return new Promise((resolve, reject) => {
    dialog.addEventListener("close", () => {
      document?.body?.classList.remove("overflow-hidden");
      resolve(dialog.returnValue === "confirm");
    }, { once: true })
  });
};
