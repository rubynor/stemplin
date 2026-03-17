import { Controller } from "@hotwired/stimulus";

const COOKIE_CONSENT_NAME = "stemplin:cookie_consent";

export default class extends Controller {
  static targets = ["banner"];

  connect() {
    if (!this.hasConsent()) {
      this.showBanner();
    }
  }

  accept() {
    this.setConsent(true);
    this.hideBanner();
  }

  decline() {
    this.setConsent(false);
    this.hideBanner();
  }

  hasConsent() {
    return document?.cookie
      ?.split(";")
      ?.some((item) => item.trim().startsWith(`${COOKIE_CONSENT_NAME}=`));
  }

  setConsent(accepted) {
    const value = accepted ? "true" : "false";
    const oneYearFromNow = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
    document.cookie = `${COOKIE_CONSENT_NAME}=${value};path=/;expires=${oneYearFromNow.toUTCString()};SameSite=Lax`;
  }

  showBanner() {
    this.bannerTarget.classList.remove("hidden");
  }

  hideBanner() {
    this.bannerTarget.classList.add("hidden");
  }
}
