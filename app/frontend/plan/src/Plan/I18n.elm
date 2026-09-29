module Plan.I18n exposing (I18n, decoder, t, tf)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)


type alias I18n =
    { strings : Dict String String
    , months : List String
    , weekdays : List String
    }


decoder : Decoder I18n
decoder =
    Decode.map3 I18n
        (Decode.field "strings" (Decode.dict Decode.string))
        (Decode.field "months" (Decode.list Decode.string))
        (Decode.field "weekdays" (Decode.list Decode.string))


{-| Look up a translation; a missing key shows up as the key itself.
-}
t : I18n -> String -> String
t i18n key =
    Dict.get key i18n.strings |> Maybe.withDefault key


{-| Translation with `%{name}` interpolation.
-}
tf : I18n -> String -> List ( String, String ) -> String
tf i18n key values =
    List.foldl
        (\( name, value ) acc -> String.replace ("%{" ++ name ++ "}") value acc)
        (t i18n key)
        values
