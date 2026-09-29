module Plan.Types exposing
    ( Actual
    , Assignee(..)
    , Assignment
    , Client
    , Milestone
    , Person
    , Placeholder
    , Project
    , Schedule
    , assigneeFromKey
    , assigneeKey
    , assignmentDecoder
    , dateDecoder
    , milestoneDecoder
    , placeholderDecoder
    , scheduleDecoder
    )

import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder)


type alias Person =
    { id : Int
    , name : String
    , email : String
    , role : String
    , capacityMinutes : Int
    , workDays : Int
    }


type alias Placeholder =
    { id : Int
    , name : String
    , roles : String
    }


type alias Client =
    { id : Int
    , name : String
    }


type alias Project =
    { id : Int
    , name : String
    , clientId : Int
    , color : String
    , billable : Bool
    }


type Assignee
    = PersonAssignee Int
    | PlaceholderAssignee Int


type alias Assignment =
    { id : Int
    , projectId : Maybe Int
    , assignee : Assignee
    , startDate : Date
    , endDate : Date
    , minutesPerDay : Int
    , notes : String
    }


type alias Milestone =
    { id : Int
    , projectId : Int
    , name : String
    , date : Date
    }


{-| Minutes tracked in Stemplin by one person on one project in the ISO week
starting on `week`.
-}
type alias Actual =
    { userId : Int
    , projectId : Int
    , week : Date
    , minutes : Int
    }


type alias Schedule =
    { rangeStart : Date
    , rangeEnd : Date
    , today : Date
    , canEdit : Bool
    , currentUserId : Int
    , defaultCapacityMinutes : Int
    , people : List Person
    , placeholders : List Placeholder
    , clients : List Client
    , projects : List Project
    , assignments : List Assignment
    , milestones : List Milestone
    , actuals : List Actual
    }


{-| A stable string key for an assignee, used for row ids and select values.
-}
assigneeKey : Assignee -> String
assigneeKey assignee =
    case assignee of
        PersonAssignee id ->
            "u" ++ String.fromInt id

        PlaceholderAssignee id ->
            "ph" ++ String.fromInt id


assigneeFromKey : String -> Maybe Assignee
assigneeFromKey key =
    if String.startsWith "ph" key then
        String.toInt (String.dropLeft 2 key) |> Maybe.map PlaceholderAssignee

    else if String.startsWith "u" key then
        String.toInt (String.dropLeft 1 key) |> Maybe.map PersonAssignee

    else
        Nothing



-- DECODERS


dateDecoder : Decoder Date
dateDecoder =
    Decode.string
        |> Decode.andThen
            (\value ->
                case Date.fromIsoString value of
                    Ok date ->
                        Decode.succeed date

                    Err error ->
                        Decode.fail error
            )


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)


personDecoder : Decoder Person
personDecoder =
    Decode.map6 Person
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.field "role" Decode.string)
        (Decode.field "capacityMinutes" Decode.int)
        (Decode.field "workDays" Decode.int)


placeholderDecoder : Decoder Placeholder
placeholderDecoder =
    Decode.map3 Placeholder
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "roles" Decode.string)


clientDecoder : Decoder Client
clientDecoder =
    Decode.map2 Client
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)


projectDecoder : Decoder Project
projectDecoder =
    Decode.map5 Project
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "clientId" Decode.int)
        (Decode.field "color" Decode.string)
        (Decode.field "billable" Decode.bool)


assigneeDecoder : Decoder Assignee
assigneeDecoder =
    Decode.oneOf
        [ Decode.field "userId" Decode.int |> Decode.map PersonAssignee
        , Decode.field "placeholderId" Decode.int |> Decode.map PlaceholderAssignee
        ]


assignmentDecoder : Decoder Assignment
assignmentDecoder =
    Decode.succeed Assignment
        |> andMap (Decode.field "id" Decode.int)
        |> andMap (Decode.field "projectId" (Decode.nullable Decode.int))
        |> andMap assigneeDecoder
        |> andMap (Decode.field "startDate" dateDecoder)
        |> andMap (Decode.field "endDate" dateDecoder)
        |> andMap (Decode.field "minutesPerDay" Decode.int)
        |> andMap (Decode.field "notes" Decode.string)


milestoneDecoder : Decoder Milestone
milestoneDecoder =
    Decode.map4 Milestone
        (Decode.field "id" Decode.int)
        (Decode.field "projectId" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "date" dateDecoder)


actualDecoder : Decoder Actual
actualDecoder =
    Decode.map4 Actual
        (Decode.field "userId" Decode.int)
        (Decode.field "projectId" Decode.int)
        (Decode.field "week" dateDecoder)
        (Decode.field "minutes" Decode.int)


scheduleDecoder : Decoder Schedule
scheduleDecoder =
    Decode.succeed Schedule
        |> andMap (Decode.at [ "range", "start" ] dateDecoder)
        |> andMap (Decode.at [ "range", "end" ] dateDecoder)
        |> andMap (Decode.field "today" dateDecoder)
        |> andMap (Decode.field "canEdit" Decode.bool)
        |> andMap (Decode.field "currentUserId" Decode.int)
        |> andMap (Decode.field "defaultCapacityMinutes" Decode.int)
        |> andMap (Decode.field "people" (Decode.list personDecoder))
        |> andMap (Decode.field "placeholders" (Decode.list placeholderDecoder))
        |> andMap (Decode.field "clients" (Decode.list clientDecoder))
        |> andMap (Decode.field "projects" (Decode.list projectDecoder))
        |> andMap (Decode.field "assignments" (Decode.list assignmentDecoder))
        |> andMap (Decode.field "milestones" (Decode.list milestoneDecoder))
        |> andMap (Decode.field "actuals" (Decode.list actualDecoder))
