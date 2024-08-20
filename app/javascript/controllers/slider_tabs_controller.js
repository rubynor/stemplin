import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['tab', 'content'];
  static values = {
    interval: { type: Number, default: 6000 },
    currentIndex: { type: Number, default: 0 },
  };

  connect() {
    this.startSlider();
  }

  disconnect() {
    this.stopSlider();
  }

  startSlider() {
    this.sliderInterval = setInterval(() => {
      if (this.shouldSlide()) {
        this.slideToNext();
      }
    }, this.intervalValue);
  }

  stopSlider() {
    clearInterval(this.sliderInterval);
  }

  shouldSlide() {
    return (
      !this.element.matches(":hover") &&
      !this.element.contains(document.activeElement)
    );
  }

  slideToNext() {
    this.currentIndexValue =
      (this.currentIndexValue + 1) % this.tabTargets.length;
    this.tabTargets[this.currentIndexValue].click();
  }

  tabClicked(event) {
    const clickedTab = event.currentTarget;
    this.currentIndexValue = this.tabTargets.indexOf(clickedTab);
    this.animateSlide();
  }

  animateSlide() {
    this.contentTargets?.forEach(content => content.classList.remove('aos-animate'));
    const currentContent = this.contentTargets[this.currentIndexValue];

    setTimeout(() => {
      currentContent?.classList.add("aos-animate");
    }, 100);
  }
}
