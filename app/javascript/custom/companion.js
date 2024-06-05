if (navigator.serviceWorker) {
  navigator.serviceWorker.register("/service_worker.js", { scope: "/" })
    .then(() => navigator.serviceWorker.ready)
}
