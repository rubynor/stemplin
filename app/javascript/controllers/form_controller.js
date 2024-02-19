import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form"
export default class extends Controller {
  connect() {
  }

  updateFrame(e) {
    const urls = JSON.parse(e.target.dataset.urls);
    const frameIds = JSON.parse(e.target.dataset.updateFrameIds);

    frameIds.forEach((frameId, index) => {
      const frame = document.getElementById(frameId);
      const paramName = e.target.dataset.paramName;

      const paramValue = e.target.value;
      frame.src = urls[index] + `?${paramName}=${paramValue}`

      frame.reload();
    });
  }

  resetFrame(e) {
    const frameIds = JSON.parse(e.target.dataset.resetFrameIds);
    frameIds.forEach(frameId => {
      const frame = document.getElementById(frameId);

      frame.innerHTML = "";
    });
  }
}
