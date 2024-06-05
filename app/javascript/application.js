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
    elementToRemove.remove();
    const dismissableDivs = document.querySelectorAll('div[data-controller="dismissable"]');
    dismissableDivs?.forEach((el) => el?.remove());
    document?.body?.classList?.remove("overflow-hidden");
  }
}

Turbo.setConfirmMethod((message, element) => {
  const dialog = document.getElementById("turbo-confirm-dialog");

  dialog.querySelector("p").innerHTML = message;
  dialog.showModal();
  document?.body?.classList.add('overflow-hidden');

  return new Promise((resolve, reject) => {
    dialog.addEventListener("close", () => {
      document?.body?.classList.remove("overflow-hidden");
      resolve(dialog.returnValue === "confirm");
    }, { once: true })
  });
});
