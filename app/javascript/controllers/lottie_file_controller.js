import { Controller } from "@hotwired/stimulus"
import { DotLottie } from '@lottiefiles/dotlottie-web'

export default class extends Controller {
    static values = {
        src: String,
        options: Object, // options refer to https://developers.lottiefiles.com/docs/dotlottie-player/dotlottie-web/properties/
    }

    connect() {
        this.initializeLottie();
    }

    initializeLottie() {
        new DotLottie({
            ...this.defaultOptions,
            ...this.optionsValue,
            src: this.srcValue,
        })
    }


    get defaultOptions() {
        return {
            autoplay: true,
            loop: true,
            canvas: this.element,
        }
    }
}
