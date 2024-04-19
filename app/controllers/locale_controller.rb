class LocaleController < ApplicationController
    def set_locale
        option =params[:locale]

        case option
        when "nb"
            redirect_to "#{root_path}?locale=nb"
            current_user.update!(locale: "nb")

        when "en"
            redirect_to "#{root_path}?locale=en"
            current_user.update!(locale: "en")
        end
    end
end
