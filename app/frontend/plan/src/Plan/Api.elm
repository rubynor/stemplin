module Plan.Api exposing
    ( AssignmentPayload
    , Config
    , createAssignments
    , createMilestone
    , createPlaceholder
    , deleteAssignment
    , deleteMilestone
    , deletePlaceholder
    , errorMessage
    , fetchSchedule
    , shiftProject
    , splitAssignment
    , updateAssignment
    , updateMilestone
    , updatePerson
    , updatePlaceholder
    , updateProjectColor
    )

import Date exposing (Date)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Plan.Types as Types exposing (Assignee(..), Assignment, Milestone, Placeholder, Schedule)
import Url.Builder as Url


type alias Config =
    { basePath : String
    , csrfToken : String
    }


{-| Turn a failed request into something to show the user. Validation errors
from Rails arrive as `{ "errors": [...] }`.
-}
errorMessage : Http.Error -> String
errorMessage error =
    case error of
        Http.BadStatus 403 ->
            "forbidden"

        Http.BadStatus status ->
            "HTTP " ++ String.fromInt status

        Http.BadBody body ->
            body

        Http.Timeout ->
            "timeout"

        Http.NetworkError ->
            "network"

        Http.BadUrl url ->
            url


{-| Like Http.expectJson, but keeps the Rails validation messages on 4xx.
-}
expectJson : (Result Http.Error a -> msg) -> Decoder a -> Http.Expect msg
expectJson toMsg decoder =
    expectBody toMsg
        (\body ->
            Decode.decodeString decoder body
                |> Result.mapError (Decode.errorToString >> Http.BadBody)
        )


expectNothing : (Result Http.Error () -> msg) -> Http.Expect msg
expectNothing toMsg =
    expectBody toMsg (\_ -> Ok ())


expectBody : (Result Http.Error a -> msg) -> (String -> Result Http.Error a) -> Http.Expect msg
expectBody toMsg onSuccess =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.GoodStatus_ _ body ->
                    onSuccess body

                Http.BadStatus_ metadata body ->
                    case Decode.decodeString (Decode.field "errors" (Decode.list Decode.string)) body of
                        Ok messages ->
                            Err (Http.BadBody (String.join ". " messages))

                        Err _ ->
                            Err (Http.BadStatus metadata.statusCode)

                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError


send : Config -> String -> String -> Maybe Encode.Value -> Http.Expect msg -> Cmd msg
send config method path body expect =
    Http.request
        { method = method
        , headers =
            [ Http.header "X-CSRF-Token" config.csrfToken
            , Http.header "Accept" "application/json"
            ]
        , url = config.basePath ++ path
        , body = body |> Maybe.map Http.jsonBody |> Maybe.withDefault Http.emptyBody
        , expect = expect
        , timeout = Just 20000
        , tracker = Nothing
        }


fetchSchedule : Config -> Date -> Date -> (Result Http.Error Schedule -> msg) -> Cmd msg
fetchSchedule config from to toMsg =
    send config
        "GET"
        (Url.absolute [ "data" ] [ Url.string "start" (Date.toIsoString from), Url.string "end" (Date.toIsoString to) ])
        Nothing
        (expectJson toMsg Types.scheduleDecoder)



-- ASSIGNMENTS


type alias AssignmentPayload =
    { projectId : Maybe Int
    , assignee : Assignee
    , startDate : Date
    , endDate : Date
    , minutesPerDay : Int
    , notes : String
    , repeatWeeks : Int
    }


encodeAssignment : AssignmentPayload -> Encode.Value
encodeAssignment payload =
    let
        ( userId, placeholderId ) =
            case payload.assignee of
                PersonAssignee id ->
                    ( Encode.int id, Encode.null )

                PlaceholderAssignee id ->
                    ( Encode.null, Encode.int id )
    in
    Encode.object
        [ ( "assignment"
          , Encode.object
                [ ( "project_id", payload.projectId |> Maybe.map Encode.int |> Maybe.withDefault Encode.null )
                , ( "user_id", userId )
                , ( "placeholder_id", placeholderId )
                , ( "start_date", Encode.string (Date.toIsoString payload.startDate) )
                , ( "end_date", Encode.string (Date.toIsoString payload.endDate) )
                , ( "minutes_per_day", Encode.int payload.minutesPerDay )
                , ( "notes", Encode.string payload.notes )
                , ( "repeat_weeks", Encode.int payload.repeatWeeks )
                ]
          )
        ]


createAssignments : Config -> AssignmentPayload -> (Result Http.Error (List Assignment) -> msg) -> Cmd msg
createAssignments config payload toMsg =
    send config "POST" "/assignments" (Just (encodeAssignment payload)) (expectJson toMsg (Decode.list Types.assignmentDecoder))


updateAssignment : Config -> Int -> AssignmentPayload -> (Result Http.Error Assignment -> msg) -> Cmd msg
updateAssignment config id payload toMsg =
    send config "PATCH" ("/assignments/" ++ String.fromInt id) (Just (encodeAssignment payload)) (expectJson toMsg Types.assignmentDecoder)


deleteAssignment : Config -> Int -> (Result Http.Error () -> msg) -> Cmd msg
deleteAssignment config id toMsg =
    send config "DELETE" ("/assignments/" ++ String.fromInt id) Nothing (expectNothing toMsg)


splitAssignment : Config -> Int -> Date -> (Result Http.Error (List Assignment) -> msg) -> Cmd msg
splitAssignment config id date toMsg =
    send config
        "POST"
        ("/assignments/" ++ String.fromInt id ++ "/split")
        (Just (Encode.object [ ( "date", Encode.string (Date.toIsoString date) ) ]))
        (expectJson toMsg (Decode.list Types.assignmentDecoder))



-- MILESTONES


encodeMilestone : Int -> String -> Date -> Encode.Value
encodeMilestone projectId name date =
    Encode.object
        [ ( "milestone"
          , Encode.object
                [ ( "project_id", Encode.int projectId )
                , ( "name", Encode.string name )
                , ( "date", Encode.string (Date.toIsoString date) )
                ]
          )
        ]


createMilestone : Config -> Int -> String -> Date -> (Result Http.Error Milestone -> msg) -> Cmd msg
createMilestone config projectId name date toMsg =
    send config "POST" "/milestones" (Just (encodeMilestone projectId name date)) (expectJson toMsg Types.milestoneDecoder)


updateMilestone : Config -> Int -> Int -> String -> Date -> (Result Http.Error Milestone -> msg) -> Cmd msg
updateMilestone config id projectId name date toMsg =
    send config "PATCH" ("/milestones/" ++ String.fromInt id) (Just (encodeMilestone projectId name date)) (expectJson toMsg Types.milestoneDecoder)


deleteMilestone : Config -> Int -> (Result Http.Error () -> msg) -> Cmd msg
deleteMilestone config id toMsg =
    send config "DELETE" ("/milestones/" ++ String.fromInt id) Nothing (expectNothing toMsg)



-- PLACEHOLDERS


encodePlaceholder : String -> String -> Encode.Value
encodePlaceholder name roles =
    Encode.object [ ( "placeholder", Encode.object [ ( "name", Encode.string name ), ( "roles", Encode.string roles ) ] ) ]


createPlaceholder : Config -> String -> String -> (Result Http.Error Placeholder -> msg) -> Cmd msg
createPlaceholder config name roles toMsg =
    send config "POST" "/placeholders" (Just (encodePlaceholder name roles)) (expectJson toMsg Types.placeholderDecoder)


updatePlaceholder : Config -> Int -> String -> String -> (Result Http.Error Placeholder -> msg) -> Cmd msg
updatePlaceholder config id name roles toMsg =
    send config "PATCH" ("/placeholders/" ++ String.fromInt id) (Just (encodePlaceholder name roles)) (expectJson toMsg Types.placeholderDecoder)


deletePlaceholder : Config -> Int -> (Result Http.Error () -> msg) -> Cmd msg
deletePlaceholder config id toMsg =
    send config "DELETE" ("/placeholders/" ++ String.fromInt id) Nothing (expectNothing toMsg)



-- PEOPLE AND PROJECTS


updatePerson : Config -> Int -> Maybe Int -> Int -> (Result Http.Error () -> msg) -> Cmd msg
updatePerson config userId capacityMinutes workDays toMsg =
    send config
        "PATCH"
        ("/people/" ++ String.fromInt userId)
        (Just
            (Encode.object
                [ ( "person"
                  , Encode.object
                        [ ( "plan_weekly_capacity_minutes", capacityMinutes |> Maybe.map Encode.int |> Maybe.withDefault Encode.null )
                        , ( "plan_work_days", Encode.int workDays )
                        ]
                  )
                ]
            )
        )
        (expectNothing toMsg)


updateProjectColor : Config -> Int -> String -> (Result Http.Error () -> msg) -> Cmd msg
updateProjectColor config projectId color toMsg =
    send config
        "PATCH"
        ("/projects/" ++ String.fromInt projectId)
        (Just (Encode.object [ ( "project", Encode.object [ ( "color", Encode.string color ) ] ) ]))
        (expectNothing toMsg)


shiftProject : Config -> Int -> Date -> Date -> (Result Http.Error () -> msg) -> Cmd msg
shiftProject config projectId from to toMsg =
    send config
        "POST"
        ("/projects/" ++ String.fromInt projectId ++ "/shift")
        (Just (Encode.object [ ( "from", Encode.string (Date.toIsoString from) ), ( "to", Encode.string (Date.toIsoString to) ) ]))
        (expectNothing toMsg)
