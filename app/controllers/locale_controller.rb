class LocaleController < ApplicationController
    def set_locale
        option =params[:locale]

        case option
        when "nb"
            redirect_to "http://0.0.0.0:3000/?locale=nb"
        when "en"
            redirect_to "http://0.0.0.0:3000/?locale=en"

        end
    end
end
