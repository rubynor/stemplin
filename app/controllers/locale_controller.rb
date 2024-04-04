class LocaleController < ApplicationController
    def set_locale
        option =params[:locale]

        case option
        when "nb"
            redirect_to "http://0.0.0.0:3000/?locale=nb"
            current_user.update!(locale: "nb")

        when "en"
            redirect_to "http://0.0.0.0:3000/?locale=en"
            current_user.update!(locale: "en")
        end
    end
end
