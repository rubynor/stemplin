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
  console.log(elementToRemove)
  if (elementToRemove) {
    const specificDialog = elementToRemove.closest('div[data-controller="ruby-ui--dialog"]');

    elementToRemove.remove();

    if (specificDialog) {
      specificDialog.remove();
    }

    document?.body?.classList?.remove("overflow-hidden");
  }
}

StreamActions.change_video = function() {
  const target = this.getAttribute("target");
  let paths = this.getAttribute("paths");
  const videoElement = document.getElementById(target);

  paths = JSON.parse(paths)
  let currentIndex = 0;

  const playNext = () => {
    if (currentIndex <= (paths.length - 1)) {
      videoElement.src = paths[currentIndex]
    } else {
      videoElement.removeEventListener("timeupdate", timeUpdate);
    }
    currentIndex = Math.min(currentIndex + 1, paths.length)
  }

  let oldTime = 0;
  const timeUpdate = (event) => {
    console.log("timeupdate")
    if (videoElement.currentTime < oldTime) {
      playNext();
      console.log("currentIndex", currentIndex)
    }
    oldTime = videoElement.currentTime;
  }

  videoElement.addEventListener("timeupdate", timeUpdate)
  playNext();
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
