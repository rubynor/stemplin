port module Main exposing (main)

{-| Stemplin Plan: a resource schedule in the spirit of Harvest Forecast.

The app renders a timeline for a window of weeks. People (and placeholders) and
projects are rows; assignments are bars that can be drawn, moved and resized
with the mouse. Everything the server sends is already scoped to what the
signed-in user may see; `canEdit` decides whether the grid is interactive.

-}

import Browser
import Browser.Events
import Date exposing (Date)
import Dict exposing (Dict)
import Html exposing (Html, a, button, div, h1, h2, h3, input, label, option, p, select, span, table, tbody, td, text, textarea, tfoot, th, thead, tr)
import Html.Attributes as A
import Html.Events as E
import Html.Keyed as Keyed
import Http
import Json.Decode as Decode exposing (Decoder)
import Plan.Api as Api exposing (AssignmentPayload)
import Plan.Calendar as Cal
import Plan.I18n as I18n exposing (I18n)
import Plan.Types as T exposing (Assignee(..), Assignment, Milestone, Person, Placeholder, Project, Schedule)
import Process
import Set exposing (Set)
import Task
import Time
import Url.Builder


port replaceUrl : String -> Cmd msg


{-| Sent when the host page drops this app to mount a fresh one (Elm apps
cannot be destroyed), so it stops listening to window events.
-}
port stop : (() -> msg) -> Sub msg


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- CONSTANTS


leftWidth : Float
leftWidth =
    264


laneHeight : Float
laneHeight =
    30


compactLaneHeight : Float
compactLaneHeight =
    22


colors : List String
colors =
    [ "orange", "green", "aqua", "blue", "purple", "magenta", "red", "gray" ]



-- MODEL


type Page
    = ProjectsPage
    | TeamPage
    | ReportPage
    | ExportPage


type Zoom
    = DayZoom
    | WeekZoom
    | MonthZoom


type HeatMode
    = DailyAvailability
    | WeeklyCapacity


type DragKind
    = Move
    | ResizeStart
    | ResizeEnd


type Drag
    = BarDrag { kind : DragKind, assignment : Assignment, originX : Float, currentX : Float, travelled : Bool }
    | CreateDrag { projectId : Maybe Int, assignee : Assignee, anchorDay : Int, originX : Float, currentX : Float }


type Modal
    = AssignmentModal AssignmentForm
    | MilestoneModal MilestoneForm
    | PlaceholderModal PlaceholderForm
    | PersonModal PersonForm
    | ProjectModal ProjectForm


type alias AssignmentForm =
    { id : Maybe Int
    , project : String
    , assignee : String
    , start : String
    , end : String
    , hours : String
    , notes : String
    , repeat : Bool
    , repeatWeeks : String
    , splitDate : String
    , confirmDelete : Bool
    , saving : Bool
    , error : Maybe String
    }


type alias MilestoneForm =
    { id : Maybe Int
    , projectId : Int
    , name : String
    , date : String
    , saving : Bool
    , error : Maybe String
    }


type alias PlaceholderForm =
    { id : Maybe Int
    , name : String
    , roles : String
    , confirmDelete : Bool
    , saving : Bool
    , error : Maybe String
    }


type alias PersonForm =
    { person : Person
    , hours : String
    , workDays : Int
    , saving : Bool
    , error : Maybe String
    }


type alias ProjectForm =
    { project : Project
    , shiftFrom : String
    , shiftTo : String
    , saving : Bool
    , error : Maybe String
    }


type ToastKind
    = Success
    | Failure


type alias Toast =
    { id : Int
    , kind : ToastKind
    , message : String
    }


type alias ExportForm =
    { view : String
    , period : String
    , timeframe : String
    , start : String
    , end : String
    }


type alias Links =
    { newProject : String
    , invite : String
    }


type alias Model =
    { config : Api.Config
    , i18n : I18n
    , links : Links
    , page : Page
    , zoom : Zoom
    , heat : HeatMode
    , anchor : Date
    , today : Date
    , viewportWidth : Int
    , schedule : Maybe Schedule
    , loading : Bool
    , loadError : Maybe String
    , requestId : Int
    , expanded : Set String
    , search : String
    , onlyScheduled : Bool
    , drag : Maybe Drag
    , modal : Maybe Modal
    , toast : Maybe Toast
    , counter : Int
    , exportForm : ExportForm
    , stopped : Bool
    }


type alias Flags =
    { basePath : String
    , csrfToken : String
    , i18n : I18n
    , page : String
    , date : Maybe String
    , zoom : String
    , today : String
    , viewportWidth : Int
    , links : Links
    }


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)


flagsDecoder : Decoder Flags
flagsDecoder =
    Decode.succeed Flags
        |> andMap (Decode.field "basePath" Decode.string)
        |> andMap (Decode.field "csrfToken" Decode.string)
        |> andMap (Decode.field "i18n" I18n.decoder)
        |> andMap (Decode.field "page" Decode.string)
        |> andMap (Decode.maybe (Decode.field "date" Decode.string))
        |> andMap (Decode.field "zoom" Decode.string)
        |> andMap (Decode.field "today" Decode.string)
        |> andMap (Decode.field "viewportWidth" Decode.int)
        |> andMap
            (Decode.field "links"
                (Decode.map2 Links
                    (Decode.field "newProject" Decode.string)
                    (Decode.field "invite" Decode.string)
                )
            )


init : Decode.Value -> ( Model, Cmd Msg )
init value =
    case Decode.decodeValue flagsDecoder value of
        Ok flags ->
            let
                today =
                    Date.fromIsoString flags.today |> Result.withDefault (Date.fromCalendarDate 2026 Time.Jan 1)

                focus =
                    flags.date
                        |> Maybe.andThen (Date.fromIsoString >> Result.toMaybe)
                        |> Maybe.withDefault today

                model =
                    { config = { basePath = flags.basePath, csrfToken = flags.csrfToken }
                    , i18n = flags.i18n
                    , links = flags.links
                    , page = pageFromSlug flags.page
                    , zoom = zoomFromSlug flags.zoom
                    , heat = DailyAvailability
                    , anchor = Date.floor Date.Monday focus
                    , today = today
                    , viewportWidth = flags.viewportWidth
                    , schedule = Nothing
                    , loading = True
                    , loadError = Nothing
                    , requestId = 0
                    , expanded = Set.empty
                    , search = ""
                    , onlyScheduled = False
                    , drag = Nothing
                    , modal = Nothing
                    , toast = Nothing
                    , counter = 0
                    , exportForm = { view = "projects", period = "weekly", timeframe = "16_weeks", start = Date.toIsoString today, end = Date.toIsoString (Date.add Date.Days 27 today) }
                    , stopped = False
                    }
            in
            fetch model

        Err error ->
            ( { config = { basePath = "/plan", csrfToken = "" }
              , i18n = { strings = Dict.empty, months = [], weekdays = [] }
              , links = { newProject = "", invite = "" }
              , page = TeamPage
              , zoom = DayZoom
              , heat = DailyAvailability
              , anchor = Date.fromCalendarDate 2026 Time.Jan 5
              , today = Date.fromCalendarDate 2026 Time.Jan 5
              , viewportWidth = 1280
              , schedule = Nothing
              , loading = False
              , loadError = Just (Decode.errorToString error)
              , requestId = 0
              , expanded = Set.empty
              , search = ""
              , onlyScheduled = False
              , drag = Nothing
              , modal = Nothing
              , toast = Nothing
              , counter = 0
              , exportForm = { view = "projects", period = "weekly", timeframe = "16_weeks", start = "", end = "" }
              , stopped = False
              }
            , Cmd.none
            )


pageFromSlug : String -> Page
pageFromSlug slug =
    case slug of
        "team" ->
            TeamPage

        "report" ->
            ReportPage

        "export" ->
            ExportPage

        _ ->
            ProjectsPage


pageSlug : Page -> String
pageSlug page =
    case page of
        ProjectsPage ->
            "projects"

        TeamPage ->
            "team"

        ReportPage ->
            "report"

        ExportPage ->
            "export"


zoomFromSlug : String -> Zoom
zoomFromSlug slug =
    case slug of
        "week" ->
            WeekZoom

        "month" ->
            MonthZoom

        _ ->
            DayZoom


zoomSlug : Zoom -> String
zoomSlug zoom =
    case zoom of
        DayZoom ->
            "day"

        WeekZoom ->
            "week"

        MonthZoom ->
            "month"



-- GEOMETRY


type alias Geometry =
    { start : Date
    , end : Date
    , days : Int
    , dayWidth : Float
    , width : Float
    }


weeksShown : Zoom -> Int
weeksShown zoom =
    case zoom of
        DayZoom ->
            4

        WeekZoom ->
            16

        MonthZoom ->
            52


minDayWidth : Zoom -> Float
minDayWidth zoom =
    case zoom of
        DayZoom ->
            30

        WeekZoom ->
            8

        MonthZoom ->
            3


stepWeeks : Zoom -> Int
stepWeeks zoom =
    case zoom of
        DayZoom ->
            1

        WeekZoom ->
            4

        MonthZoom ->
            13


geometry : Model -> Geometry
geometry model =
    let
        days =
            weeksShown model.zoom * 7

        available =
            toFloat (model.viewportWidth - 48) - leftWidth - 2

        dayWidth =
            max (minDayWidth model.zoom) (available / toFloat days)
    in
    { start = model.anchor
    , end = Date.add Date.Days (days - 1) model.anchor
    , days = days
    , dayWidth = dayWidth
    , width = dayWidth * toFloat days
    }


xOf : Geometry -> Date -> Float
xOf geo date =
    toFloat (Date.diff Date.Days geo.start date) * geo.dayWidth


px : Float -> String
px value =
    String.fromFloat value ++ "px"



-- UPDATE


type AssignmentField
    = FProject
    | FAssignee
    | FStart
    | FEnd
    | FHours
    | FTotal
    | FNotes
    | FRepeatWeeks
    | FSplitDate


type Msg
    = NoOp
    | GotSchedule Int (Result Http.Error Schedule)
    | SetPage Page
    | SetZoom Zoom
    | SetHeat HeatMode
    | Navigate Int
    | GoToday
    | Resized Int
    | ToggleRow String
    | ExpandAll Bool
    | SetSearch String
    | SetOnlyScheduled Bool
    | StartBarDrag DragKind Assignment Float
    | StartCreateDrag (Maybe Int) Assignee Float Float
    | MouseMoved Float
    | MouseReleased Bool
    | ViewAssignment Assignment
    | NewAssignment (Maybe Int) Assignee Date Date
    | AssignProjectTo Assignee String
    | AssignPersonTo (Maybe Int) String
    | UpdateAssignment AssignmentField String
    | SetRepeat Bool
    | SubmitAssignment
    | AskDeleteAssignment
    | DeleteAssignment Int
    | SplitAssignment Int
    | AssignmentsCreated (Result Http.Error (List Assignment))
    | AssignmentSplit Int (Result Http.Error (List Assignment))
    | AssignmentUpdated (Result Http.Error Assignment)
    | AssignmentDeleted Int (Result Http.Error ())
    | DragSaved (Result Http.Error Assignment)
    | DragCopied (Result Http.Error (List Assignment))
    | NewMilestone Int Date
    | EditMilestone Milestone
    | UpdateMilestoneName String
    | UpdateMilestoneDate String
    | SubmitMilestone
    | DeleteMilestone Int
    | MilestoneSaved (Result Http.Error Milestone)
    | MilestoneDeleted Int (Result Http.Error ())
    | OpenPlaceholder (Maybe Placeholder)
    | UpdatePlaceholderName String
    | UpdatePlaceholderRoles String
    | SubmitPlaceholder
    | AskDeletePlaceholder
    | DeletePlaceholder Int
    | PlaceholderSaved (Result Http.Error Placeholder)
    | PlaceholderDeleted Int (Result Http.Error ())
    | OpenPerson Person
    | UpdatePersonHours String
    | TogglePersonDay Int
    | SubmitPerson
    | PersonSaved Int (Maybe Int) Int (Result Http.Error ())
    | OpenProject Project
    | ChooseColor Int String
    | ColorSaved Int String (Result Http.Error ())
    | UpdateShiftFrom String
    | UpdateShiftTo String
    | SubmitShift
    | ShiftSaved (Result Http.Error ())
    | CloseModal
    | DismissToast Int
    | KeyDown String String
    | UpdateExport String String
    | Stop


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GotSchedule id result ->
            if id /= model.requestId then
                ( model, Cmd.none )

            else
                case result of
                    Ok schedule ->
                        ( { model | schedule = Just schedule, loading = False, loadError = Nothing, today = schedule.today }, Cmd.none )

                    Err error ->
                        ( { model | loading = False, loadError = Just (Api.errorMessage error) }, Cmd.none )

        SetPage page ->
            let
                next =
                    { model | page = page }
            in
            ( next, syncUrl next )

        SetZoom zoom ->
            reload { model | zoom = zoom }

        SetHeat heat ->
            ( { model | heat = heat }, Cmd.none )

        Navigate direction ->
            reload { model | anchor = Date.add Date.Weeks (direction * stepWeeks model.zoom) model.anchor }

        GoToday ->
            reload { model | anchor = Date.floor Date.Monday model.today }

        Resized width ->
            ( { model | viewportWidth = width }, Cmd.none )

        ToggleRow key ->
            ( { model
                | expanded =
                    if Set.member key model.expanded then
                        Set.remove key model.expanded

                    else
                        Set.insert key model.expanded
              }
            , Cmd.none
            )

        ExpandAll expand ->
            ( { model
                | expanded =
                    if expand then
                        model.schedule |> Maybe.map (allRowKeys model) |> Maybe.withDefault Set.empty

                    else
                        Set.empty
              }
            , Cmd.none
            )

        SetSearch value ->
            ( { model | search = value }, Cmd.none )

        SetOnlyScheduled value ->
            ( { model | onlyScheduled = value }, Cmd.none )

        StartBarDrag kind assignment x ->
            ( { model | drag = Just (BarDrag { kind = kind, assignment = assignment, originX = x, currentX = x, travelled = False }) }, Cmd.none )

        StartCreateDrag projectId assignee offsetX pageX ->
            let
                geo =
                    geometry model
            in
            ( { model
                | drag =
                    Just
                        (CreateDrag
                            { projectId = projectId
                            , assignee = assignee
                            , anchorDay = floor (offsetX / geo.dayWidth)
                            , originX = pageX
                            , currentX = pageX
                            }
                        )
              }
            , Cmd.none
            )

        MouseMoved x ->
            case model.drag of
                Just (BarDrag drag) ->
                    ( { model | drag = Just (BarDrag { drag | currentX = x, travelled = drag.travelled || abs (x - drag.originX) >= 4 }) }, Cmd.none )

                Just (CreateDrag drag) ->
                    ( { model | drag = Just (CreateDrag { drag | currentX = x }) }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        MouseReleased altKey ->
            finishDrag altKey { model | drag = Nothing } model.drag

        ViewAssignment assignment ->
            ( { model | modal = Just (AssignmentModal (formFromAssignment model assignment)) }, Cmd.none )

        NewAssignment projectId assignee from to ->
            ( { model | modal = Just (AssignmentModal (newAssignmentForm model projectId assignee from to)) }, Cmd.none )

        AssignProjectTo assignee value ->
            let
                projectId =
                    String.toInt value
            in
            if value == "" then
                ( model, Cmd.none )

            else
                ( { model
                    | counter = model.counter + 1
                    , modal = Just (AssignmentModal (newAssignmentForm model projectId assignee (defaultStart model) (Date.add Date.Days 4 (defaultStart model))))
                  }
                , Cmd.none
                )

        AssignPersonTo projectId key ->
            case T.assigneeFromKey key of
                Just assignee ->
                    ( { model
                        | counter = model.counter + 1
                        , modal = Just (AssignmentModal (newAssignmentForm model projectId assignee (defaultStart model) (Date.add Date.Days 4 (defaultStart model))))
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        UpdateAssignment field value ->
            updateAssignmentForm model (setAssignmentField model field value)

        SetRepeat value ->
            updateAssignmentForm model (\form -> { form | repeat = value })

        SubmitAssignment ->
            case model.modal of
                Just (AssignmentModal form) ->
                    case assignmentPayload model form of
                        Ok payload ->
                            ( { model | modal = Just (AssignmentModal { form | saving = True, error = Nothing }) }
                            , case form.id of
                                Just id ->
                                    Api.updateAssignment model.config id payload AssignmentUpdated

                                Nothing ->
                                    Api.createAssignments model.config payload AssignmentsCreated
                            )

                        Err error ->
                            ( { model | modal = Just (AssignmentModal { form | error = Just error }) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        AskDeleteAssignment ->
            updateAssignmentForm model (\form -> { form | confirmDelete = True })

        DeleteAssignment id ->
            ( model, Api.deleteAssignment model.config id (AssignmentDeleted id) )

        SplitAssignment id ->
            case model.modal of
                Just (AssignmentModal form) ->
                    case Date.fromIsoString form.splitDate of
                        Ok date ->
                            ( model, Api.splitAssignment model.config id date (AssignmentSplit id) )

                        Err _ ->
                            ( { model | modal = Just (AssignmentModal { form | error = Just (t model "errors.split_date") }) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        AssignmentsCreated result ->
            case result of
                Ok created ->
                    { model | modal = Nothing }
                        |> mapSchedule (\s -> { s | assignments = s.assignments ++ created })
                        |> toast Success (t model "toast.assignment_saved")

                Err error ->
                    ( modalError model error, Cmd.none )

        AssignmentSplit id result ->
            case result of
                Ok parts ->
                    { model | modal = Nothing }
                        |> mapSchedule (\s -> { s | assignments = List.filter (\x -> x.id /= id) s.assignments ++ parts })
                        |> toast Success (t model "toast.assignment_split")

                Err error ->
                    ( modalError model error, Cmd.none )

        AssignmentUpdated result ->
            case result of
                Ok saved ->
                    { model | modal = Nothing }
                        |> mapSchedule (replaceAssignment saved)
                        |> toast Success (t model "toast.assignment_saved")

                Err error ->
                    ( modalError model error, Cmd.none )

        AssignmentDeleted id result ->
            case result of
                Ok () ->
                    { model | modal = Nothing }
                        |> mapSchedule (\s -> { s | assignments = List.filter (\x -> x.id /= id) s.assignments })
                        |> toast Success (t model "toast.assignment_deleted")

                Err error ->
                    ( modalError model error, Cmd.none )

        DragSaved result ->
            case result of
                Ok saved ->
                    ( mapSchedule (replaceAssignment saved) model, Cmd.none )

                Err error ->
                    -- The optimistic move is wrong now; reload the truth.
                    fetch model |> andToast Failure (t model "toast.save_failed" ++ " " ++ Api.errorMessage error)

        DragCopied result ->
            case result of
                Ok created ->
                    mapSchedule (\s -> { s | assignments = s.assignments ++ created }) model
                        |> toast Success (t model "toast.assignment_copied")

                Err error ->
                    toast Failure (t model "toast.save_failed" ++ " " ++ Api.errorMessage error) model

        NewMilestone projectId date ->
            ( { model | modal = Just (MilestoneModal { id = Nothing, projectId = projectId, name = "", date = Date.toIsoString date, saving = False, error = Nothing }) }, Cmd.none )

        EditMilestone milestone ->
            ( { model | modal = Just (MilestoneModal { id = Just milestone.id, projectId = milestone.projectId, name = milestone.name, date = Date.toIsoString milestone.date, saving = False, error = Nothing }) }, Cmd.none )

        UpdateMilestoneName value ->
            updateMilestoneForm model (\form -> { form | name = value })

        UpdateMilestoneDate value ->
            updateMilestoneForm model (\form -> { form | date = value })

        SubmitMilestone ->
            case model.modal of
                Just (MilestoneModal form) ->
                    case ( String.trim form.name, Date.fromIsoString form.date ) of
                        ( "", _ ) ->
                            ( { model | modal = Just (MilestoneModal { form | error = Just (t model "errors.name_required") }) }, Cmd.none )

                        ( name, Ok date ) ->
                            ( { model | modal = Just (MilestoneModal { form | saving = True }) }
                            , case form.id of
                                Just id ->
                                    Api.updateMilestone model.config id form.projectId name date MilestoneSaved

                                Nothing ->
                                    Api.createMilestone model.config form.projectId name date MilestoneSaved
                            )

                        ( _, Err _ ) ->
                            ( { model | modal = Just (MilestoneModal { form | error = Just (t model "errors.date_required") }) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        DeleteMilestone id ->
            ( model, Api.deleteMilestone model.config id (MilestoneDeleted id) )

        MilestoneSaved result ->
            case result of
                Ok milestone ->
                    { model | modal = Nothing }
                        |> mapSchedule (\s -> { s | milestones = milestone :: List.filter (\m -> m.id /= milestone.id) s.milestones })
                        |> toast Success (t model "toast.milestone_saved")

                Err error ->
                    ( modalError model error, Cmd.none )

        MilestoneDeleted id result ->
            case result of
                Ok () ->
                    { model | modal = Nothing }
                        |> mapSchedule (\s -> { s | milestones = List.filter (\m -> m.id /= id) s.milestones })
                        |> toast Success (t model "toast.milestone_deleted")

                Err error ->
                    ( modalError model error, Cmd.none )

        OpenPlaceholder maybePlaceholder ->
            let
                form =
                    case maybePlaceholder of
                        Just placeholder ->
                            { id = Just placeholder.id, name = placeholder.name, roles = placeholder.roles, confirmDelete = False, saving = False, error = Nothing }

                        Nothing ->
                            { id = Nothing, name = "", roles = "", confirmDelete = False, saving = False, error = Nothing }
            in
            ( { model | modal = Just (PlaceholderModal form) }, Cmd.none )

        UpdatePlaceholderName value ->
            updatePlaceholderForm model (\form -> { form | name = value })

        UpdatePlaceholderRoles value ->
            updatePlaceholderForm model (\form -> { form | roles = value })

        SubmitPlaceholder ->
            case model.modal of
                Just (PlaceholderModal form) ->
                    if String.trim form.name == "" then
                        ( { model | modal = Just (PlaceholderModal { form | error = Just (t model "errors.name_required") }) }, Cmd.none )

                    else
                        ( { model | modal = Just (PlaceholderModal { form | saving = True }) }
                        , case form.id of
                            Just id ->
                                Api.updatePlaceholder model.config id (String.trim form.name) form.roles PlaceholderSaved

                            Nothing ->
                                Api.createPlaceholder model.config (String.trim form.name) form.roles PlaceholderSaved
                        )

                _ ->
                    ( model, Cmd.none )

        AskDeletePlaceholder ->
            updatePlaceholderForm model (\form -> { form | confirmDelete = True })

        DeletePlaceholder id ->
            ( model, Api.deletePlaceholder model.config id (PlaceholderDeleted id) )

        PlaceholderSaved result ->
            case result of
                Ok placeholder ->
                    { model | modal = Nothing }
                        |> mapSchedule
                            (\s ->
                                { s
                                    | placeholders =
                                        (placeholder :: List.filter (\x -> x.id /= placeholder.id) s.placeholders)
                                            |> List.sortBy (.name >> String.toLower)
                                }
                            )
                        |> toast Success (t model "toast.placeholder_saved")

                Err error ->
                    ( modalError model error, Cmd.none )

        PlaceholderDeleted id result ->
            case result of
                Ok () ->
                    { model | modal = Nothing }
                        |> mapSchedule
                            (\s ->
                                { s
                                    | placeholders = List.filter (\x -> x.id /= id) s.placeholders
                                    , assignments = List.filter (\x -> x.assignee /= PlaceholderAssignee id) s.assignments
                                }
                            )
                        |> toast Success (t model "toast.placeholder_deleted")

                Err error ->
                    ( modalError model error, Cmd.none )

        OpenPerson person ->
            ( { model
                | modal =
                    Just
                        (PersonModal
                            { person = person
                            , hours = Cal.formatHours (toFloat person.capacityMinutes)
                            , workDays = person.workDays
                            , saving = False
                            , error = Nothing
                            }
                        )
              }
            , Cmd.none
            )

        UpdatePersonHours value ->
            updatePersonForm model (\form -> { form | hours = value })

        TogglePersonDay bit ->
            updatePersonForm model
                (\form ->
                    let
                        isSet =
                            modBy 2 (form.workDays // (2 ^ bit)) == 1
                    in
                    { form
                        | workDays =
                            if isSet then
                                form.workDays - 2 ^ bit

                            else
                                form.workDays + 2 ^ bit
                    }
                )

        SubmitPerson ->
            case model.modal of
                Just (PersonModal form) ->
                    case parseHours form.hours of
                        Just hours ->
                            let
                                minutes =
                                    Just (round (hours * 60))
                            in
                            ( { model | modal = Just (PersonModal { form | saving = True }) }
                            , Api.updatePerson model.config form.person.id minutes form.workDays (PersonSaved form.person.id minutes form.workDays)
                            )

                        Nothing ->
                            ( { model | modal = Just (PersonModal { form | error = Just (t model "errors.hours_invalid") }) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        PersonSaved userId minutes workDays result ->
            case result of
                Ok () ->
                    { model | modal = Nothing }
                        |> mapSchedule
                            (\s ->
                                { s
                                    | people =
                                        List.map
                                            (\person ->
                                                if person.id == userId then
                                                    { person | capacityMinutes = Maybe.withDefault person.capacityMinutes minutes, workDays = workDays }

                                                else
                                                    person
                                            )
                                            s.people
                                }
                            )
                        |> toast Success (t model "toast.person_saved")

                Err error ->
                    ( modalError model error, Cmd.none )

        OpenProject project ->
            ( { model
                | modal =
                    Just
                        (ProjectModal
                            { project = project
                            , shiftFrom = Date.toIsoString (defaultStart model)
                            , shiftTo = Date.toIsoString (Date.add Date.Weeks 1 (defaultStart model))
                            , saving = False
                            , error = Nothing
                            }
                        )
              }
            , Cmd.none
            )

        ChooseColor projectId color ->
            let
                recolor s =
                    { s
                        | projects =
                            List.map
                                (\project ->
                                    if project.id == projectId then
                                        { project | color = color }

                                    else
                                        project
                                )
                                s.projects
                    }

                modal =
                    case model.modal of
                        Just (ProjectModal form) ->
                            Just (ProjectModal { form | project = (\p -> { p | color = color }) form.project })

                        other ->
                            other
            in
            ( mapSchedule recolor { model | modal = modal }, Api.updateProjectColor model.config projectId color (ColorSaved projectId color) )

        ColorSaved _ _ result ->
            case result of
                Ok () ->
                    ( model, Cmd.none )

                Err error ->
                    fetch model |> andToast Failure (t model "toast.save_failed" ++ " " ++ Api.errorMessage error)

        UpdateShiftFrom value ->
            updateProjectForm model (\form -> { form | shiftFrom = value })

        UpdateShiftTo value ->
            updateProjectForm model (\form -> { form | shiftTo = value })

        SubmitShift ->
            case model.modal of
                Just (ProjectModal form) ->
                    case ( Date.fromIsoString form.shiftFrom, Date.fromIsoString form.shiftTo ) of
                        ( Ok from, Ok to ) ->
                            ( { model | modal = Just (ProjectModal { form | saving = True }) }, Api.shiftProject model.config form.project.id from to ShiftSaved )

                        _ ->
                            ( { model | modal = Just (ProjectModal { form | error = Just (t model "errors.date_required") }) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ShiftSaved result ->
            case result of
                Ok () ->
                    fetch { model | modal = Nothing } |> andToast Success (t model "toast.timeline_shifted")

                Err error ->
                    ( modalError model error, Cmd.none )

        CloseModal ->
            ( { model | modal = Nothing }, Cmd.none )

        DismissToast id ->
            if Maybe.map .id model.toast == Just id then
                ( { model | toast = Nothing }, Cmd.none )

            else
                ( model, Cmd.none )

        KeyDown key tag ->
            if key == "Escape" then
                ( { model | modal = Nothing, drag = Nothing }, Cmd.none )

            else if model.modal /= Nothing || List.member tag [ "INPUT", "TEXTAREA", "SELECT" ] || model.page == ExportPage then
                ( model, Cmd.none )

            else
                case key of
                    "ArrowLeft" ->
                        update (Navigate -1) model

                    "ArrowRight" ->
                        update (Navigate 1) model

                    "t" ->
                        update GoToday model

                    _ ->
                        ( model, Cmd.none )

        UpdateExport field value ->
            let
                form =
                    model.exportForm

                next =
                    case field of
                        "view" ->
                            { form | view = value }

                        "period" ->
                            { form | period = value }

                        "timeframe" ->
                            { form | timeframe = value }

                        "start" ->
                            { form | start = value }

                        _ ->
                            { form | end = value }
            in
            ( { model | exportForm = next }, Cmd.none )

        Stop ->
            ( { model | stopped = True, drag = Nothing }, Cmd.none )



-- UPDATE HELPERS


fetch : Model -> ( Model, Cmd Msg )
fetch model =
    let
        geo =
            geometry model

        id =
            model.requestId + 1
    in
    ( { model | requestId = id, loading = True }
    , Api.fetchSchedule model.config geo.start geo.end (GotSchedule id)
    )


reload : Model -> ( Model, Cmd Msg )
reload model =
    let
        ( next, cmd ) =
            fetch model
    in
    ( next, Cmd.batch [ cmd, syncUrl next ] )


syncUrl : Model -> Cmd Msg
syncUrl model =
    replaceUrl
        (model.config.basePath
            ++ "/"
            ++ pageSlug model.page
            ++ Url.Builder.toQuery [ Url.Builder.string "date" (Date.toIsoString model.anchor), Url.Builder.string "zoom" (zoomSlug model.zoom) ]
        )


mapSchedule : (Schedule -> Schedule) -> Model -> Model
mapSchedule fn model =
    { model | schedule = Maybe.map fn model.schedule }


replaceAssignment : Assignment -> Schedule -> Schedule
replaceAssignment saved schedule =
    { schedule
        | assignments =
            List.map
                (\x ->
                    if x.id == saved.id then
                        saved

                    else
                        x
                )
                schedule.assignments
    }


toast : ToastKind -> String -> Model -> ( Model, Cmd Msg )
toast kind message model =
    let
        id =
            model.counter + 1
    in
    ( { model | counter = id, toast = Just { id = id, kind = kind, message = message } }
    , Process.sleep 3500 |> Task.perform (\_ -> DismissToast id)
    )


andToast : ToastKind -> String -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
andToast kind message ( model, cmd ) =
    let
        ( next, toastCmd ) =
            toast kind message model
    in
    ( next, Cmd.batch [ cmd, toastCmd ] )


modalError : Model -> Http.Error -> Model
modalError model error =
    let
        message =
            Just (Api.errorMessage error)
    in
    case model.modal of
        Just (AssignmentModal form) ->
            { model | modal = Just (AssignmentModal { form | saving = False, error = message }) }

        Just (MilestoneModal form) ->
            { model | modal = Just (MilestoneModal { form | saving = False, error = message }) }

        Just (PlaceholderModal form) ->
            { model | modal = Just (PlaceholderModal { form | saving = False, error = message }) }

        Just (PersonModal form) ->
            { model | modal = Just (PersonModal { form | saving = False, error = message }) }

        Just (ProjectModal form) ->
            { model | modal = Just (ProjectModal { form | saving = False, error = message }) }

        Nothing ->
            model


updateAssignmentForm : Model -> (AssignmentForm -> AssignmentForm) -> ( Model, Cmd Msg )
updateAssignmentForm model fn =
    case model.modal of
        Just (AssignmentModal form) ->
            ( { model | modal = Just (AssignmentModal (fn form)) }, Cmd.none )

        _ ->
            ( model, Cmd.none )


updateMilestoneForm : Model -> (MilestoneForm -> MilestoneForm) -> ( Model, Cmd Msg )
updateMilestoneForm model fn =
    case model.modal of
        Just (MilestoneModal form) ->
            ( { model | modal = Just (MilestoneModal (fn form)) }, Cmd.none )

        _ ->
            ( model, Cmd.none )


updatePlaceholderForm : Model -> (PlaceholderForm -> PlaceholderForm) -> ( Model, Cmd Msg )
updatePlaceholderForm model fn =
    case model.modal of
        Just (PlaceholderModal form) ->
            ( { model | modal = Just (PlaceholderModal (fn form)) }, Cmd.none )

        _ ->
            ( model, Cmd.none )


updatePersonForm : Model -> (PersonForm -> PersonForm) -> ( Model, Cmd Msg )
updatePersonForm model fn =
    case model.modal of
        Just (PersonModal form) ->
            ( { model | modal = Just (PersonModal (fn form)) }, Cmd.none )

        _ ->
            ( model, Cmd.none )


updateProjectForm : Model -> (ProjectForm -> ProjectForm) -> ( Model, Cmd Msg )
updateProjectForm model fn =
    case model.modal of
        Just (ProjectModal form) ->
            ( { model | modal = Just (ProjectModal (fn form)) }, Cmd.none )

        _ ->
            ( model, Cmd.none )


{-| New assignments start today when today is on screen, otherwise at the
first visible day.
-}
defaultStart : Model -> Date
defaultStart model =
    let
        geo =
            geometry model
    in
    if Date.isBetween geo.start geo.end model.today then
        model.today

    else
        geo.start


dayDelta : Model -> Float -> Float -> Int
dayDelta model originX currentX =
    round ((currentX - originX) / (geometry model).dayWidth)


{-| Where an assignment is drawn while it is being dragged.
-}
draggedAssignment : Model -> Assignment -> Assignment
draggedAssignment model assignment =
    case model.drag of
        Just (BarDrag drag) ->
            if drag.assignment.id == assignment.id then
                applyDrag drag.kind (dayDelta model drag.originX drag.currentX) assignment

            else
                assignment

        _ ->
            assignment


applyDrag : DragKind -> Int -> Assignment -> Assignment
applyDrag kind delta assignment =
    case kind of
        Move ->
            { assignment | startDate = Date.add Date.Days delta assignment.startDate, endDate = Date.add Date.Days delta assignment.endDate }

        ResizeStart ->
            { assignment | startDate = Date.min assignment.endDate (Date.add Date.Days delta assignment.startDate) }

        ResizeEnd ->
            { assignment | endDate = Date.max assignment.startDate (Date.add Date.Days delta assignment.endDate) }


finishDrag : Bool -> Model -> Maybe Drag -> ( Model, Cmd Msg )
finishDrag altKey model drag =
    case drag of
        Just (BarDrag { kind, assignment, originX, currentX, travelled }) ->
            let
                delta =
                    dayDelta model originX currentX

                moved =
                    applyDrag kind delta assignment
            in
            if not travelled then
                -- A click, not a drag.
                update (ViewAssignment assignment) model

            else if delta == 0 then
                ( model, Cmd.none )

            else if altKey && kind == Move then
                ( model, Api.createAssignments model.config (payloadFromAssignment moved) DragCopied )

            else
                ( mapSchedule (replaceAssignment moved) model
                , Api.updateAssignment model.config assignment.id (payloadFromAssignment moved) DragSaved
                )

        Just (CreateDrag { projectId, assignee, anchorDay, originX, currentX }) ->
            let
                geo =
                    geometry model

                endDay =
                    anchorDay + dayDelta model originX currentX

                from =
                    Date.add Date.Days (min anchorDay endDay) geo.start

                to =
                    Date.add Date.Days (max anchorDay endDay) geo.start
            in
            update (NewAssignment projectId assignee from to) model

        Nothing ->
            ( model, Cmd.none )


payloadFromAssignment : Assignment -> AssignmentPayload
payloadFromAssignment assignment =
    { projectId = assignment.projectId
    , assignee = assignment.assignee
    , startDate = assignment.startDate
    , endDate = assignment.endDate
    , minutesPerDay = assignment.minutesPerDay
    , notes = assignment.notes
    , repeatWeeks = 0
    }


projectValue : Maybe Int -> String
projectValue projectId =
    Maybe.map String.fromInt projectId |> Maybe.withDefault "timeoff"


formFromAssignment : Model -> Assignment -> AssignmentForm
formFromAssignment model assignment =
    { id = Just assignment.id
    , project = projectValue assignment.projectId
    , assignee = T.assigneeKey assignment.assignee
    , start = Date.toIsoString assignment.startDate
    , end = Date.toIsoString assignment.endDate
    , hours = Cal.formatHours (toFloat assignment.minutesPerDay)
    , notes = assignment.notes
    , repeat = False
    , repeatWeeks = "4"
    , splitDate =
        Date.toIsoString
            (Date.add Date.Days (max 1 (Date.diff Date.Days assignment.startDate assignment.endDate // 2 + 1)) assignment.startDate)
    , confirmDelete = False
    , saving = False
    , error = Nothing
    }


newAssignmentForm : Model -> Maybe Int -> Assignee -> Date -> Date -> AssignmentForm
newAssignmentForm model projectId assignee from to =
    let
        perDay =
            case ( projectId, assignee ) of
                ( _, PersonAssignee id ) ->
                    findPerson model id
                        |> Maybe.map (\person -> Cal.dailyCapacity person.workDays person.capacityMinutes)
                        |> Maybe.withDefault 450

                ( _, PlaceholderAssignee _ ) ->
                    model.schedule |> Maybe.map (\s -> toFloat s.defaultCapacityMinutes / 5) |> Maybe.withDefault 450
    in
    { id = Nothing
    , project = projectValue projectId
    , assignee = T.assigneeKey assignee
    , start = Date.toIsoString from
    , end = Date.toIsoString to
    , hours = Cal.formatHours perDay
    , notes = ""
    , repeat = False
    , repeatWeeks = "4"
    , splitDate = ""
    , confirmDelete = False
    , saving = False
    , error = Nothing
    }


setAssignmentField : Model -> AssignmentField -> String -> AssignmentForm -> AssignmentForm
setAssignmentField model field value form =
    case field of
        FProject ->
            { form | project = value }

        FAssignee ->
            { form | assignee = value }

        FStart ->
            { form | start = value }

        FEnd ->
            { form | end = value }

        FHours ->
            { form | hours = value }

        FTotal ->
            -- Editing the total spreads it evenly over the working days.
            case ( parseHours value, formWorkDays model form ) of
                ( Just total, days ) ->
                    if days > 0 then
                        { form | hours = Cal.formatHours (total * 60 / toFloat days) }

                    else
                        form

                _ ->
                    form

        FNotes ->
            { form | notes = value }

        FRepeatWeeks ->
            { form | repeatWeeks = value }

        FSplitDate ->
            { form | splitDate = value }


parseHours : String -> Maybe Float
parseHours value =
    String.toFloat (String.replace "," "." (String.trim value))
        |> Maybe.andThen
            (\hours ->
                if hours >= 0 && hours <= 168 then
                    Just hours

                else
                    Nothing
            )


formWorkDays : Model -> AssignmentForm -> Int
formWorkDays model form =
    case ( Date.fromIsoString form.start, Date.fromIsoString form.end ) of
        ( Ok from, Ok to ) ->
            Cal.countWorkDays (assigneeWorkDays model (T.assigneeFromKey form.assignee)) from to

        _ ->
            0


assigneeWorkDays : Model -> Maybe Assignee -> Int
assigneeWorkDays model assignee =
    case assignee of
        Just (PersonAssignee id) ->
            findPerson model id |> Maybe.map .workDays |> Maybe.withDefault 31

        _ ->
            31


assignmentPayload : Model -> AssignmentForm -> Result String AssignmentPayload
assignmentPayload model form =
    case ( T.assigneeFromKey form.assignee, ( Date.fromIsoString form.start, Date.fromIsoString form.end ), parseHours form.hours ) of
        ( Nothing, _, _ ) ->
            Err (t model "errors.assignee_required")

        ( _, ( Err _, _ ), _ ) ->
            Err (t model "errors.date_required")

        ( _, ( _, Err _ ), _ ) ->
            Err (t model "errors.date_required")

        ( _, _, Nothing ) ->
            Err (t model "errors.hours_invalid")

        ( Just assignee, ( Ok from, Ok to ), Just hours ) ->
            if Date.compare to from == LT then
                Err (t model "errors.end_before_start")

            else if hours <= 0 || hours > 24 then
                Err (t model "errors.hours_invalid")

            else
                Ok
                    { projectId = String.toInt form.project
                    , assignee = assignee
                    , startDate = from
                    , endDate = to
                    , minutesPerDay = round (hours * 60)
                    , notes = form.notes
                    , repeatWeeks =
                        if form.repeat && form.id == Nothing then
                            String.toInt form.repeatWeeks |> Maybe.withDefault 1 |> clamp 1 52

                        else
                            0
                    }



-- LOOKUPS


t : Model -> String -> String
t model =
    I18n.t model.i18n


tf : Model -> String -> List ( String, String ) -> String
tf model =
    I18n.tf model.i18n


findPerson : Model -> Int -> Maybe Person
findPerson model id =
    model.schedule |> Maybe.andThen (\s -> List.filter (\person -> person.id == id) s.people |> List.head)


findProject : Schedule -> Int -> Maybe Project
findProject schedule id =
    List.filter (\project -> project.id == id) schedule.projects |> List.head


clientName : Schedule -> Int -> String
clientName schedule clientId =
    List.filter (\client -> client.id == clientId) schedule.clients |> List.head |> Maybe.map .name |> Maybe.withDefault ""


assigneeName : Schedule -> Assignee -> String
assigneeName schedule assignee =
    case assignee of
        PersonAssignee id ->
            List.filter (\person -> person.id == id) schedule.people |> List.head |> Maybe.map .name |> Maybe.withDefault "?"

        PlaceholderAssignee id ->
            List.filter (\placeholder -> placeholder.id == id) schedule.placeholders |> List.head |> Maybe.map .name |> Maybe.withDefault "?"


projectLabel : Model -> Schedule -> Maybe Int -> String
projectLabel model schedule projectId =
    case projectId of
        Just id ->
            findProject schedule id |> Maybe.map .name |> Maybe.withDefault "—"

        Nothing ->
            t model "time_off"


colorOf : Schedule -> Maybe Int -> String
colorOf schedule projectId =
    case projectId of
        Just id ->
            findProject schedule id |> Maybe.map .color |> Maybe.withDefault "gray"

        Nothing ->
            "timeoff"


matchesSearch : Model -> List String -> Bool
matchesSearch model haystack =
    let
        needle =
            String.toLower (String.trim model.search)
    in
    needle == "" || List.any (String.toLower >> String.contains needle) haystack


allRowKeys : Model -> Schedule -> Set String
allRowKeys model schedule =
    case model.page of
        TeamPage ->
            Set.fromList
                (List.map (\person -> T.assigneeKey (PersonAssignee person.id)) schedule.people
                    ++ List.map (\placeholder -> T.assigneeKey (PlaceholderAssignee placeholder.id)) schedule.placeholders
                )

        _ ->
            Set.fromList ("p-timeoff" :: List.map (\project -> "p" ++ String.fromInt project.id) schedule.projects)


initials : String -> String
initials name =
    name
        |> String.words
        |> List.take 2
        |> List.map (String.left 1 >> String.toUpper)
        |> String.concat


avatarColor : Int -> String
avatarColor id =
    List.drop (modBy (List.length colors) id) colors |> List.head |> Maybe.withDefault "blue"


formatDate : Model -> Date -> String
formatDate model date =
    String.fromInt (Date.day date) ++ " " ++ monthName model date


monthName : Model -> Date -> String
monthName model date =
    List.drop (Date.monthNumber date - 1) model.i18n.months |> List.head |> Maybe.withDefault (Date.format "MMM" date)


weekdayInitial : Model -> Date -> String
weekdayInitial model date =
    List.drop (Date.weekdayNumber date - 1) model.i18n.weekdays |> List.head |> Maybe.withDefault "" |> String.left 1


hoursLabel : Float -> String
hoursLabel minutes =
    Cal.formatHours minutes ++ "h"



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.stopped then
        Sub.none

    else
        subscriptionsWhileRunning model


subscriptionsWhileRunning : Model -> Sub Msg
subscriptionsWhileRunning model =
    Sub.batch
        [ stop (\_ -> Stop)
        , Browser.Events.onResize (\width _ -> Resized width)
        , Browser.Events.onKeyDown
            (Decode.map2 KeyDown
                (Decode.field "key" Decode.string)
                (Decode.oneOf [ Decode.at [ "target", "tagName" ] Decode.string, Decode.succeed "" ])
            )
        , case model.drag of
            Just _ ->
                Sub.batch
                    [ Browser.Events.onMouseMove (Decode.map MouseMoved (Decode.field "pageX" Decode.float))
                    , Browser.Events.onMouseUp (Decode.map MouseReleased (Decode.field "altKey" Decode.bool))
                    ]

            Nothing ->
                Sub.none
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ A.class "plan-app"
        , A.classList [ ( "plan-dragging", model.drag /= Nothing ), ( "plan-loading", model.loading ) ]
        ]
        [ viewHead model
        , case ( model.schedule, model.loadError ) of
            ( _, Just error ) ->
                div [ A.class "plan-card plan-empty" ] [ text (t model "errors.load_failed" ++ " (" ++ error ++ ")") ]

            ( Nothing, Nothing ) ->
                div [ A.class "plan-card plan-empty" ] [ text (t model "loading") ]

            ( Just schedule, Nothing ) ->
                case model.page of
                    ProjectsPage ->
                        viewGrid model schedule (projectRows model schedule)

                    TeamPage ->
                        viewGrid model schedule (teamRows model schedule)

                    ReportPage ->
                        viewReport model schedule

                    ExportPage ->
                        viewExport model
        , viewModal model
        , viewToast model
        ]


viewHead : Model -> Html Msg
viewHead model =
    div [ A.class "plan-head" ]
        [ div [ A.class "flex items-center gap-x-4 gap-y-3 flex-wrap" ]
            [ h1 [ A.class "page-title" ] [ text (t model "title") ]
            , div [ A.class "plan-tabs", A.attribute "role" "tablist" ]
                (List.map (viewTab model)
                    [ ( ProjectsPage, "tabs.projects" ), ( TeamPage, "tabs.team" ), ( ReportPage, "tabs.report" ), ( ExportPage, "tabs.export" ) ]
                )
            ]
        , if model.page == ExportPage then
            text ""

          else
            div [ A.class "flex items-center gap-2 flex-wrap" ]
                [ if model.page == TeamPage then
                    select [ A.class "plan-select", A.attribute "aria-label" (t model "heat.label"), E.on "change" (Decode.map heatFromValue E.targetValue) ]
                        [ option [ A.value "daily", A.selected (model.heat == DailyAvailability) ] [ text (t model "heat.daily") ]
                        , option [ A.value "weekly", A.selected (model.heat == WeeklyCapacity) ] [ text (t model "heat.weekly") ]
                        ]

                  else
                    text ""
                , if model.page == ReportPage then
                    text ""

                  else
                    button [ A.class "plan-icon-button", A.title (t model "expand_all"), E.onClick (ExpandAll (Set.isEmpty model.expanded)) ]
                        [ text
                            (if Set.isEmpty model.expanded then
                                "⇕"

                             else
                                "⇳"
                            )
                        ]
                , div [ A.class "plan-segment" ]
                    (List.map
                        (\( zoom, key ) ->
                            button [ A.classList [ ( "is-active", model.zoom == zoom ) ], E.onClick (SetZoom zoom) ] [ text (t model key) ]
                        )
                        [ ( DayZoom, "zoom.day" ), ( WeekZoom, "zoom.week" ), ( MonthZoom, "zoom.month" ) ]
                    )
                , div [ A.class "plan-segment" ]
                    [ button [ A.title (t model "nav.previous"), A.attribute "aria-label" (t model "nav.previous"), E.onClick (Navigate -1) ] [ text "←" ]
                    , button [ E.onClick GoToday ] [ text (t model "nav.today") ]
                    , button [ A.title (t model "nav.next"), A.attribute "aria-label" (t model "nav.next"), E.onClick (Navigate 1) ] [ text "→" ]
                    ]
                , span [ A.class "plan-range tnum" ] [ text (rangeLabel model) ]
                ]
        ]


heatFromValue : String -> Msg
heatFromValue value =
    if value == "weekly" then
        SetHeat WeeklyCapacity

    else
        SetHeat DailyAvailability


viewTab : Model -> ( Page, String ) -> Html Msg
viewTab model ( page, key ) =
    button
        [ A.classList [ ( "is-active", model.page == page ) ]
        , A.attribute "role" "tab"
        , A.attribute "aria-selected"
            (if model.page == page then
                "true"

             else
                "false"
            )
        , E.onClick (SetPage page)
        ]
        [ text (t model key) ]


rangeLabel : Model -> String
rangeLabel model =
    let
        geo =
            geometry model
    in
    if Date.year geo.start == Date.year geo.end then
        formatDate model geo.start ++ " – " ++ formatDate model geo.end ++ " " ++ String.fromInt (Date.year geo.end)

    else
        formatDate model geo.start ++ " " ++ String.fromInt (Date.year geo.start) ++ " – " ++ formatDate model geo.end ++ " " ++ String.fromInt (Date.year geo.end)



-- GRID


type alias Row =
    { key : String
    , class : String
    , height : Float
    , left : Html Msg
    , timelineAttrs : List (Html.Attribute Msg)
    , timeline : List (Html Msg)
    }


viewGrid : Model -> Schedule -> List Row -> Html Msg
viewGrid model schedule rows =
    let
        geo =
            geometry model

        todayX =
            xOf geo model.today

        showToday =
            Date.isBetween geo.start geo.end model.today
    in
    div [ A.class "plan-card" ]
        [ div [ A.class "plan-scroll" ]
            [ div
                [ A.class ("plan-grid plan-zoom-" ++ zoomSlug model.zoom)
                , A.attribute "style" ("--dw:" ++ px geo.dayWidth ++ ";width:" ++ px (leftWidth + geo.width))
                ]
                [ viewTimeHeader model geo
                , Keyed.node "div" [ A.class "plan-rows" ] (List.map (\row -> ( row.key, viewRow geo row )) rows)
                , if showToday then
                    div [ A.class "plan-today-line", A.style "left" (px (leftWidth + todayX + geo.dayWidth / 2)) ] []

                  else
                    text ""
                ]
            ]
        , if List.isEmpty rows then
            div [ A.class "plan-empty" ] [ text (t model "empty") ]

          else
            text ""
        ]


viewRow : Geometry -> Row -> Html Msg
viewRow geo row =
    div [ A.class ("plan-row " ++ row.class), A.style "height" (px row.height), A.attribute "data-row" row.key ]
        [ div [ A.class "plan-left" ] [ row.left ]
        , div (A.class "plan-timeline" :: A.style "width" (px geo.width) :: row.timelineAttrs) row.timeline
        ]


viewTimeHeader : Model -> Geometry -> Html Msg
viewTimeHeader model geo =
    let
        dates =
            List.range 0 (geo.days - 1) |> List.map (\i -> Date.add Date.Days i geo.start)

        months =
            dates
                |> List.filter (\date -> Date.day date == 1 || date == geo.start)
                |> List.map
                    (\date ->
                        div [ A.class "plan-month", A.style "left" (px (xOf geo date)) ]
                            [ text (monthName model date ++ " " ++ String.fromInt (Date.year date)) ]
                    )

        weeks =
            List.range 0 (geo.days // 7 - 1) |> List.map (\w -> Date.add Date.Weeks w geo.start)

        ticks =
            case model.zoom of
                DayZoom ->
                    List.map
                        (\date ->
                            div
                                [ A.class "plan-tick"
                                , A.classList [ ( "is-weekend", Date.weekdayNumber date > 5 ), ( "is-today", date == model.today ) ]
                                , A.style "left" (px (xOf geo date))
                                , A.style "width" (px geo.dayWidth)
                                ]
                                [ span [ A.class "plan-tick-day" ] [ text (weekdayInitial model date) ]
                                , span [ A.class "plan-tick-num tnum" ] [ text (String.fromInt (Date.day date)) ]
                                ]
                        )
                        dates

                WeekZoom ->
                    List.map
                        (\date ->
                            div [ A.class "plan-tick", A.classList [ ( "is-today", Date.isBetween date (Date.add Date.Days 6 date) model.today ) ], A.style "left" (px (xOf geo date)), A.style "width" (px (geo.dayWidth * 7)) ]
                                [ span [ A.class "plan-tick-day" ] [ text (t model "week_short" ++ String.fromInt (Date.weekNumber date)) ]
                                , span [ A.class "plan-tick-num tnum" ] [ text (String.fromInt (Date.day date)) ]
                                ]
                        )
                        weeks

                MonthZoom ->
                    List.map
                        (\date ->
                            div [ A.class "plan-tick", A.classList [ ( "is-today", Date.isBetween date (Date.add Date.Days 6 date) model.today ) ], A.style "left" (px (xOf geo date)), A.style "width" (px (geo.dayWidth * 7)) ]
                                [ span [ A.class "plan-tick-num tnum" ] [ text (String.fromInt (Date.weekNumber date)) ] ]
                        )
                        weeks
    in
    div [ A.class "plan-row plan-header-row" ]
        [ div [ A.class "plan-left plan-search" ]
            [ input
                [ A.type_ "search"
                , A.class "plan-search-input"
                , A.placeholder (t model "search")
                , A.value model.search
                , E.onInput SetSearch
                ]
                []
            ]
        , div [ A.class "plan-timeline plan-header-timeline", A.style "width" (px geo.width) ]
            [ div [ A.class "plan-months" ] months
            , div [ A.class "plan-ticks" ] ticks
            ]
        ]



-- TEAM ROWS


teamRows : Model -> Schedule -> List Row
teamRows model schedule =
    let
        geo =
            geometry model

        assignmentsOf assignee =
            List.filter (\x -> x.assignee == assignee) schedule.assignments

        projectNames assignee =
            assignmentsOf assignee |> List.map (\x -> projectLabel model schedule x.projectId)

        placeholderRows =
            schedule.placeholders
                |> List.filter (\placeholder -> matchesSearch model (placeholder.name :: placeholder.roles :: projectNames (PlaceholderAssignee placeholder.id)))
                |> List.concatMap
                    (\placeholder ->
                        assigneeRows model schedule geo (PlaceholderAssignee placeholder.id) (assignmentsOf (PlaceholderAssignee placeholder.id))
                    )

        personRows =
            schedule.people
                |> List.filter (\person -> matchesSearch model (person.name :: person.email :: projectNames (PersonAssignee person.id)))
                |> List.concatMap
                    (\person ->
                        assigneeRows model schedule geo (PersonAssignee person.id) (assignmentsOf (PersonAssignee person.id))
                    )
    in
    placeholderRows ++ personRows ++ [ teamFooterRow model schedule ]


assigneeRows : Model -> Schedule -> Geometry -> Assignee -> List Assignment -> List Row
assigneeRows model schedule geo assignee assignments =
    let
        key =
            T.assigneeKey assignee

        expanded =
            Set.member key model.expanded

        groups =
            assignments
                |> List.map .projectId
                |> uniqueMaybes
                |> List.sortBy (\projectId -> ( sortProjectKey schedule projectId, 0 ))

        parent =
            { key = key
            , class = "plan-parent"
            , height = 52
            , left = viewAssigneeCell model schedule assignee expanded
            , timelineAttrs = []
            , timeline = viewHeat model geo assignee assignments
            }

        children =
            List.map
                (\projectId ->
                    let
                        inGroup =
                            List.filter (\x -> x.projectId == projectId) assignments
                    in
                    barRow model
                        schedule
                        geo
                        { key = key ++ "-" ++ projectValue projectId
                        , projectId = projectId
                        , assignee = assignee
                        , left = viewProjectChip model schedule projectId
                        , assignments = inGroup
                        , label = \x -> hoursLabel (toFloat x.minutesPerDay)
                        }
                )
                groups

        addRow =
            if schedule.canEdit then
                [ { key = key ++ "-add"
                  , class = "plan-add"
                  , height = 44
                  , left =
                        Keyed.node "div"
                            [ A.class "w-full" ]
                            [ ( String.fromInt model.counter
                              , select [ A.class "plan-select w-full", E.on "change" (Decode.map (AssignProjectTo assignee) E.targetValue) ]
                                    (option [ A.attribute "value" "", A.selected True ] [ text (t model "assign_to_project") ] :: projectOptions model schedule "")
                              )
                            ]
                  , timelineAttrs = []
                  , timeline = []
                  }
                ]

            else
                []
    in
    if expanded then
        parent :: children ++ addRow

    else
        [ parent ]


sortProjectKey : Schedule -> Maybe Int -> String
sortProjectKey schedule projectId =
    case projectId |> Maybe.andThen (findProject schedule) of
        Just project ->
            "1" ++ String.toLower (clientName schedule project.clientId ++ " " ++ project.name)

        Nothing ->
            "0"


uniqueMaybes : List (Maybe Int) -> List (Maybe Int)
uniqueMaybes values =
    List.foldl
        (\value acc ->
            if List.member value acc then
                acc

            else
                acc ++ [ value ]
        )
        []
        values


viewAssigneeCell : Model -> Schedule -> Assignee -> Bool -> Html Msg
viewAssigneeCell model schedule assignee expanded =
    let
        key =
            T.assigneeKey assignee

        ( name, subtitle, avatar ) =
            case assignee of
                PersonAssignee id ->
                    case List.filter (\person -> person.id == id) schedule.people |> List.head of
                        Just person ->
                            ( person.name
                            , tf model "capacity_per_week" [ ( "hours", Cal.formatHours (toFloat person.capacityMinutes) ) ]
                            , span [ A.class ("plan-avatar plan-c-" ++ avatarColor person.id) ] [ text (initials person.name) ]
                            )

                        Nothing ->
                            ( "?", "", text "" )

                PlaceholderAssignee id ->
                    case List.filter (\placeholder -> placeholder.id == id) schedule.placeholders |> List.head of
                        Just placeholder ->
                            ( placeholder.name
                            , if placeholder.roles == "" then
                                t model "placeholder"

                              else
                                placeholder.roles
                            , span [ A.class "plan-avatar plan-avatar-placeholder" ] [ text "?" ]
                            )

                        Nothing ->
                            ( "?", "", text "" )

        editMsg =
            case assignee of
                PersonAssignee id ->
                    findPerson model id |> Maybe.map OpenPerson

                PlaceholderAssignee id ->
                    List.filter (\placeholder -> placeholder.id == id) schedule.placeholders |> List.head |> Maybe.map (Just >> OpenPlaceholder)
    in
    div [ A.class "plan-assignee" ]
        [ button [ A.class "plan-expand", E.onClick (ToggleRow key), A.attribute "aria-expanded" (boolString expanded) ]
            [ span [ A.class "plan-chevron", A.classList [ ( "is-open", expanded ) ] ] [ text "›" ]
            , avatar
            , span [ A.class "min-w-0 text-left" ]
                [ span [ A.class "plan-name" ] [ text name ]
                , span [ A.class "plan-sub" ] [ text subtitle ]
                ]
            ]
        , case ( schedule.canEdit, editMsg ) of
            ( True, Just msg ) ->
                button [ A.class "plan-row-action", A.title (t model "edit"), E.onClick msg ] [ text "⋯" ]

            _ ->
                text ""
        ]


boolString : Bool -> String
boolString value =
    if value then
        "true"

    else
        "false"


viewProjectChip : Model -> Schedule -> Maybe Int -> Html Msg
viewProjectChip model schedule projectId =
    case projectId |> Maybe.andThen (findProject schedule) of
        Just project ->
            div [ A.class "plan-child-label" ]
                [ span [ A.class ("plan-dot plan-c-" ++ project.color) ] []
                , span [ A.class "min-w-0" ]
                    [ span [ A.class "plan-sub" ] [ text (clientName schedule project.clientId) ]
                    , span [ A.class "plan-name plan-name-sm" ] [ text project.name ]
                    ]
                ]

        Nothing ->
            div [ A.class "plan-child-label" ]
                [ span [ A.class "plan-dot plan-c-timeoff" ] []
                , span [ A.class "plan-name plan-name-sm" ] [ text (t model "time_off") ]
                ]


projectOptions : Model -> Schedule -> String -> List (Html Msg)
projectOptions model schedule selected =
    Html.node "optgroup"
        [ A.attribute "label" (t model "time_off") ]
        [ option [ A.value "timeoff", A.selected (selected == "timeoff") ] [ text (t model "time_off") ] ]
        :: List.map
            (\client ->
                Html.node "optgroup"
                    [ A.attribute "label" client.name ]
                    (schedule.projects
                        |> List.filter (\project -> project.clientId == client.id)
                        |> List.map (\project -> option [ A.value (String.fromInt project.id), A.selected (selected == String.fromInt project.id) ] [ text project.name ])
                    )
            )
            schedule.clients


assigneeOptions : Model -> Schedule -> String -> List (Html Msg)
assigneeOptions model schedule selected =
    [ Html.node "optgroup"
        [ A.attribute "label" (t model "people") ]
        (List.map
            (\person ->
                let
                    key =
                        T.assigneeKey (PersonAssignee person.id)
                in
                option [ A.value key, A.selected (selected == key) ] [ text person.name ]
            )
            schedule.people
        )
    , if List.isEmpty schedule.placeholders then
        text ""

      else
        Html.node "optgroup"
            [ A.attribute "label" (t model "placeholders") ]
            (List.map
                (\placeholder ->
                    let
                        key =
                            T.assigneeKey (PlaceholderAssignee placeholder.id)
                    in
                    option [ A.value key, A.selected (selected == key) ] [ text placeholder.name ]
                )
                schedule.placeholders
            )
    ]


teamFooterRow : Model -> Schedule -> Row
teamFooterRow model schedule =
    { key = "team-footer"
    , class = "plan-footer"
    , height = 56
    , left =
        if schedule.canEdit then
            div [ A.class "flex items-center gap-2" ]
                [ button [ A.class "plan-button", E.onClick (OpenPlaceholder Nothing) ] [ text ("+ " ++ t model "add_placeholder") ]
                , a [ A.class "plan-link", A.href model.links.invite ] [ text (t model "invite_people") ]
                ]

        else
            text ""
    , timelineAttrs = []
    , timeline = []
    }



-- HEATMAP


viewHeat : Model -> Geometry -> Assignee -> List Assignment -> List (Html Msg)
viewHeat model geo assignee assignments =
    let
        person =
            case assignee of
                PersonAssignee id ->
                    findPerson model id

                PlaceholderAssignee _ ->
                    Nothing

        mask =
            person |> Maybe.map .workDays |> Maybe.withDefault 31

        visible =
            List.map (draggedAssignment model) assignments
    in
    case ( model.heat, model.zoom ) of
        ( DailyAvailability, DayZoom ) ->
            List.range 0 (geo.days - 1)
                |> List.map (\i -> Date.add Date.Days i geo.start)
                |> List.filter (Cal.isWorkDay mask)
                |> List.map
                    (\date ->
                        let
                            scheduled =
                                visible
                                    |> List.filter (\x -> Cal.covers x date)
                                    |> List.map .minutesPerDay
                                    |> List.sum
                                    |> toFloat
                        in
                        case person of
                            Just p ->
                                heatCell geo (xOf geo date) geo.dayWidth (Cal.dailyCapacity mask p.capacityMinutes) scheduled (Cal.formatHours (Cal.dailyCapacity mask p.capacityMinutes - scheduled))

                            Nothing ->
                                if scheduled > 0 then
                                    heatCell geo (xOf geo date) geo.dayWidth scheduled scheduled (Cal.formatHours scheduled)

                                else
                                    text ""
                    )

        _ ->
            List.range 0 (geo.days // 7 - 1)
                |> List.map
                    (\w ->
                        let
                            from =
                                Date.add Date.Weeks w geo.start

                            to =
                                Date.add Date.Days 6 from

                            scheduled =
                                visible |> List.map (Cal.minutesInRange mask from to) |> List.sum |> toFloat

                            x =
                                xOf geo from

                            width =
                                geo.dayWidth * 7
                        in
                        case person of
                            Just p ->
                                let
                                    capacity =
                                        toFloat p.capacityMinutes

                                    label =
                                        if model.heat == WeeklyCapacity && model.zoom /= MonthZoom then
                                            Cal.formatHours scheduled ++ " / " ++ Cal.formatHours capacity

                                        else if model.heat == WeeklyCapacity then
                                            Cal.formatHours scheduled

                                        else
                                            Cal.formatHours (capacity - scheduled)
                                in
                                heatCell geo x width capacity scheduled label

                            Nothing ->
                                if scheduled > 0 then
                                    heatCell geo x width scheduled scheduled (Cal.formatHours scheduled)

                                else
                                    text ""
                    )


{-| One availability cell. The fill shows how much of the capacity is booked.
-}
heatCell : Geometry -> Float -> Float -> Float -> Float -> String -> Html Msg
heatCell geo x width capacity scheduled label =
    let
        state =
            if scheduled > capacity + 0.5 then
                "is-over"

            else if capacity > 0 && scheduled >= capacity - 0.5 then
                "is-full"

            else if scheduled > 0 then
                "is-partial"

            else
                "is-free"

        ratio =
            if capacity <= 0 then
                1

            else
                min 1 (scheduled / capacity)
    in
    div
        [ A.class ("plan-heat " ++ state)
        , A.attribute "data-date" (Date.toIsoString (Date.add Date.Days (round (x / geo.dayWidth)) geo.start))
        , A.style "left" (px (x + 1))
        , A.style "width" (px (width - 2))
        ]
        [ div [ A.class "plan-heat-fill", A.style "height" (String.fromFloat (ratio * 100) ++ "%") ] []
        , span [ A.class "plan-heat-label tnum" ] [ text label ]
        ]



-- BARS


type alias BarRowSpec =
    { key : String
    , projectId : Maybe Int
    , assignee : Assignee
    , left : Html Msg
    , assignments : List Assignment
    , label : Assignment -> String
    }


{-| A child row: one assignee on one project, with draggable bars and
click-and-drag to create.
-}
barRow : Model -> Schedule -> Geometry -> BarRowSpec -> Row
barRow model schedule geo spec =
    let
        ( lanes, laneCount ) =
            packLanes (List.map (draggedAssignment model) spec.assignments)

        creating =
            case model.drag of
                Just (CreateDrag drag) ->
                    if drag.projectId == spec.projectId && drag.assignee == spec.assignee then
                        let
                            endDay =
                                drag.anchorDay + dayDelta model drag.originX drag.currentX
                        in
                        [ div
                            [ A.class "plan-ghost"
                            , A.style "left" (px (toFloat (min drag.anchorDay endDay) * geo.dayWidth))
                            , A.style "width" (px (toFloat (abs (endDay - drag.anchorDay) + 1) * geo.dayWidth))
                            ]
                            []
                        ]

                    else
                        []

                _ ->
                    []

        createAttrs =
            if schedule.canEdit then
                [ E.custom "mousedown"
                    (Decode.map3 (\button offsetX pageX -> ( button, offsetX, pageX ))
                        (Decode.field "button" Decode.int)
                        (Decode.field "offsetX" Decode.float)
                        (Decode.field "pageX" Decode.float)
                        |> Decode.andThen
                            (\( button, offsetX, pageX ) ->
                                if button == 0 then
                                    Decode.succeed { message = StartCreateDrag spec.projectId spec.assignee offsetX pageX, stopPropagation = True, preventDefault = True }

                                else
                                    Decode.fail "not the primary button"
                            )
                    )
                , A.class "is-editable"
                , A.title (t model "drag_to_create")
                ]

            else
                []
    in
    { key = spec.key
    , class = "plan-child"
    , height = max 38 (toFloat laneCount * laneHeight + 8)
    , left = spec.left
    , timelineAttrs = createAttrs
    , timeline = List.map (\( lane, x ) -> viewBar model schedule geo 0 laneHeight lane (spec.label x) x) lanes ++ creating
    }


{-| Greedy interval packing: each bar goes in the first lane that is free.
-}
packLanes : List Assignment -> ( List ( Int, Assignment ), Int )
packLanes assignments =
    let
        place assignment ( placed, laneEnds ) =
            let
                free =
                    laneEnds
                        |> List.indexedMap Tuple.pair
                        |> List.filter (\( _, end ) -> Date.compare end assignment.startDate == LT)
                        |> List.head
                        |> Maybe.map Tuple.first
            in
            case free of
                Just lane ->
                    ( ( lane, assignment ) :: placed
                    , List.indexedMap
                        (\i end ->
                            if i == lane then
                                assignment.endDate

                            else
                                end
                        )
                        laneEnds
                    )

                Nothing ->
                    ( ( List.length laneEnds, assignment ) :: placed, laneEnds ++ [ assignment.endDate ] )

        ( result, ends ) =
            assignments
                |> List.sortWith (\x y -> Date.compare x.startDate y.startDate)
                |> List.foldl place ( [], [] )
    in
    ( List.reverse result, max 1 (List.length ends) )


viewBar : Model -> Schedule -> Geometry -> Float -> Float -> Int -> String -> Assignment -> Html Msg
viewBar model schedule geo topOffset rowLane lane label assignment =
    let
        x =
            xOf geo assignment.startDate

        width =
            toFloat (Cal.daysBetween assignment.startDate assignment.endDate) * geo.dayWidth

        isDragging =
            case model.drag of
                Just (BarDrag drag) ->
                    drag.assignment.id == assignment.id

                _ ->
                    False

        total =
            Cal.minutesInRange (assigneeWorkDays model (Just assignment.assignee)) assignment.startDate assignment.endDate assignment

        tooltip =
            String.join " · "
                (List.filter ((/=) "")
                    [ projectLabel model schedule assignment.projectId
                    , assigneeName schedule assignment.assignee
                    , tf model "per_day" [ ( "hours", Cal.formatHours (toFloat assignment.minutesPerDay) ) ]
                    , formatDate model assignment.startDate ++ " – " ++ formatDate model assignment.endDate
                    , tf model "total_hours" [ ( "hours", Cal.formatHours (toFloat total) ) ]
                    , assignment.notes
                    ]
                )

        pointer kind =
            E.custom "mousedown"
                (Decode.map2 Tuple.pair (Decode.field "button" Decode.int) (Decode.field "pageX" Decode.float)
                    |> Decode.andThen
                        (\( button, pageX ) ->
                            if button == 0 then
                                Decode.succeed { message = StartBarDrag kind assignment pageX, stopPropagation = True, preventDefault = True }

                            else
                                Decode.fail "not the primary button"
                        )
                )

        interaction =
            if schedule.canEdit then
                [ pointer Move ]

            else
                [ E.stopPropagationOn "mousedown" (Decode.succeed ( NoOp, True ))
                , E.onClick (ViewAssignment assignment)
                ]

        handles =
            if schedule.canEdit then
                [ div [ A.class "plan-handle plan-handle-start", pointer ResizeStart ] []
                , div [ A.class "plan-handle plan-handle-end", pointer ResizeEnd ] []
                ]

            else
                []
    in
    div
        ([ A.class ("plan-bar plan-c-" ++ colorOf schedule assignment.projectId)
         , A.classList [ ( "is-dragging", isDragging ), ( "is-editable", schedule.canEdit ), ( "has-notes", assignment.notes /= "" ) ]
         , A.style "left" (px (x + 1))
         , A.style "width" (px (max 4 (width - 2)))
         , A.style "top" (px (topOffset + toFloat lane * rowLane + 4))
         , A.style "height" (px (rowLane - 6))
         , A.title tooltip
         , A.attribute "data-assignment-id" (String.fromInt assignment.id)
         ]
            ++ interaction
        )
        (span [ A.class "plan-bar-label tnum", A.style "margin-left" (px (clamp 0 (max 0 (width - 40)) -x)) ] [ text label ] :: handles)



-- PROJECT ROWS


projectRows : Model -> Schedule -> List Row
projectRows model schedule =
    let
        geo =
            geometry model

        assignmentsOn projectId =
            List.filter (\x -> x.projectId == projectId) schedule.assignments

        names projectId =
            assignmentsOn projectId |> List.map (.assignee >> assigneeName schedule)

        timeOff =
            if List.isEmpty (assignmentsOn Nothing) || not (matchesSearch model (t model "time_off" :: names Nothing)) then
                []

            else
                projectGroupRows model schedule geo Nothing (assignmentsOn Nothing)

        projects =
            schedule.projects
                |> List.filter (\project -> not model.onlyScheduled || not (List.isEmpty (assignmentsOn (Just project.id))))
                |> List.filter (\project -> matchesSearch model (project.name :: clientName schedule project.clientId :: names (Just project.id)))
                |> List.concatMap (\project -> projectGroupRows model schedule geo (Just project.id) (assignmentsOn (Just project.id)))
    in
    timeOff ++ projects ++ [ projectsFooterRow model schedule ]


projectGroupRows : Model -> Schedule -> Geometry -> Maybe Int -> List Assignment -> List Row
projectGroupRows model schedule geo projectId assignments =
    let
        key =
            "p" ++ Maybe.withDefault "-timeoff" (Maybe.map String.fromInt projectId)

        expanded =
            Set.member key model.expanded

        project =
            projectId |> Maybe.andThen (findProject schedule)

        milestones =
            case projectId of
                Just id ->
                    List.filter (\m -> m.projectId == id) schedule.milestones

                Nothing ->
                    []

        ( lanes, laneCount ) =
            if expanded then
                ( [], 0 )

            else
                packLanes (List.map (draggedAssignment model) assignments)

        compactLabel x =
            initials (assigneeName schedule x.assignee) ++ " " ++ hoursLabel (toFloat x.minutesPerDay)

        milestoneAttrs =
            case ( schedule.canEdit, projectId ) of
                ( True, Just id ) ->
                    [ E.on "click"
                        (Decode.field "offsetX" Decode.float
                            |> Decode.map (\offsetX -> NewMilestone id (Date.add Date.Days (floor (offsetX / geo.dayWidth)) geo.start))
                        )
                    , A.class "is-milestone-target"
                    , A.title (t model "click_to_add_milestone")
                    ]

                _ ->
                    []

        parent =
            { key = key
            , class = "plan-parent plan-project-parent"
            , height = max 52 (toFloat laneCount * compactLaneHeight + 22)
            , left = viewProjectCell model schedule project expanded key
            , timelineAttrs = milestoneAttrs
            , timeline =
                List.map (\( lane, x ) -> viewBar model schedule geo 16 compactLaneHeight lane (compactLabel x) x) lanes
                    ++ List.map (viewMilestone model schedule geo) milestones
            }

        assignees =
            assignments
                |> List.map .assignee
                |> List.foldl
                    (\x acc ->
                        if List.member x acc then
                            acc

                        else
                            acc ++ [ x ]
                    )
                    []
                |> List.sortBy (assigneeName schedule >> String.toLower)

        children =
            List.map
                (\assignee ->
                    barRow model
                        schedule
                        geo
                        { key = key ++ "-" ++ T.assigneeKey assignee
                        , projectId = projectId
                        , assignee = assignee
                        , left = viewAssigneeChip model schedule assignee
                        , assignments = List.filter (\x -> x.assignee == assignee) assignments
                        , label = \x -> hoursLabel (toFloat x.minutesPerDay)
                        }
                )
                assignees

        addRow =
            if schedule.canEdit then
                [ { key = key ++ "-add"
                  , class = "plan-add"
                  , height = 44
                  , left =
                        Keyed.node "div"
                            [ A.class "w-full" ]
                            [ ( String.fromInt model.counter
                              , select [ A.class "plan-select w-full", E.on "change" (Decode.map (AssignPersonTo projectId) E.targetValue) ]
                                    (option [ A.attribute "value" "", A.selected True ] [ text (t model "assign_person") ] :: assigneeOptions model schedule "")
                              )
                            ]
                  , timelineAttrs = []
                  , timeline = []
                  }
                ]

            else
                []
    in
    if expanded then
        parent :: children ++ addRow

    else
        [ parent ]


viewProjectCell : Model -> Schedule -> Maybe Project -> Bool -> String -> Html Msg
viewProjectCell model schedule project expanded key =
    let
        ( color, client, name ) =
            case project of
                Just p ->
                    ( p.color, clientName schedule p.clientId, p.name )

                Nothing ->
                    ( "timeoff", "", t model "time_off" )
    in
    div [ A.class "plan-assignee" ]
        [ span [ A.class ("plan-stripe plan-c-" ++ color) ] []
        , button [ A.class "plan-expand", E.onClick (ToggleRow key), A.attribute "aria-expanded" (boolString expanded) ]
            [ span [ A.class "plan-chevron", A.classList [ ( "is-open", expanded ) ] ] [ text "›" ]
            , span [ A.class "min-w-0 text-left" ]
                [ span [ A.class "plan-sub" ] [ text client ]
                , span [ A.class "plan-name" ] [ text name ]
                ]
            ]
        , case ( schedule.canEdit, project ) of
            ( True, Just p ) ->
                button [ A.class "plan-row-action", A.title (t model "edit"), E.onClick (OpenProject p) ] [ text "⋯" ]

            _ ->
                text ""
        ]


viewAssigneeChip : Model -> Schedule -> Assignee -> Html Msg
viewAssigneeChip model schedule assignee =
    let
        name =
            assigneeName schedule assignee

        avatar =
            case assignee of
                PersonAssignee id ->
                    span [ A.class ("plan-avatar plan-avatar-sm plan-c-" ++ avatarColor id) ] [ text (initials name) ]

                PlaceholderAssignee _ ->
                    span [ A.class "plan-avatar plan-avatar-sm plan-avatar-placeholder" ] [ text "?" ]
    in
    div [ A.class "plan-child-label" ] [ avatar, span [ A.class "plan-name plan-name-sm" ] [ text name ] ]


viewMilestone : Model -> Schedule -> Geometry -> Milestone -> Html Msg
viewMilestone model schedule geo milestone =
    div
        [ A.class "plan-milestone"
        , A.attribute "data-milestone-id" (String.fromInt milestone.id)
        , A.style "left" (px (xOf geo milestone.date + geo.dayWidth / 2))
        , A.title (milestone.name ++ " · " ++ formatDate model milestone.date)
        , E.stopPropagationOn "click"
            (Decode.succeed
                ( if schedule.canEdit then
                    EditMilestone milestone

                  else
                    NoOp
                , True
                )
            )
        ]
        [ span [ A.class "plan-milestone-flag" ] []
        , span [ A.class "plan-milestone-label" ] [ text milestone.name ]
        ]


projectsFooterRow : Model -> Schedule -> Row
projectsFooterRow model schedule =
    { key = "projects-footer"
    , class = "plan-footer"
    , height = 56
    , left =
        div [ A.class "flex items-center gap-3" ]
            [ if schedule.canEdit then
                a [ A.class "plan-button", A.href model.links.newProject ] [ text ("+ " ++ t model "new_project") ]

              else
                text ""
            , label [ A.class "plan-check" ]
                [ input [ A.type_ "checkbox", A.class "form-checkbox", A.checked model.onlyScheduled, E.onCheck SetOnlyScheduled ] []
                , text (t model "only_scheduled")
                ]
            ]
    , timelineAttrs = []
    , timeline = []
    }



-- REPORT


viewReport : Model -> Schedule -> Html Msg
viewReport model schedule =
    let
        geo =
            geometry model

        tracked userFilter projectFilter =
            schedule.actuals
                |> List.filter (\actual -> userFilter actual.userId && projectFilter actual.projectId)
                |> List.map .minutes
                |> List.sum

        toDate =
            Date.min geo.end model.today

        plannedUntil until mask filter =
            schedule.assignments
                |> List.filter filter
                |> List.map (Cal.minutesInRange mask geo.start until)
                |> List.sum

        planned =
            plannedUntil geo.end

        personRows =
            schedule.people
                |> List.filter (\person -> matchesSearch model [ person.name, person.email ])
                |> List.map
                    (\person ->
                        let
                            mine x =
                                x.assignee == PersonAssignee person.id

                            capacity =
                                round (Cal.dailyCapacity person.workDays person.capacityMinutes * toFloat (Cal.countWorkDays person.workDays geo.start geo.end))

                            timeOff =
                                planned person.workDays (\x -> mine x && x.projectId == Nothing)

                            work =
                                planned person.workDays (\x -> mine x && x.projectId /= Nothing)

                            done =
                                tracked ((==) person.id) (always True)

                            workToDate =
                                plannedUntil toDate person.workDays (\x -> mine x && x.projectId /= Nothing)

                            available =
                                max 0 (capacity - timeOff)
                        in
                        tr []
                            [ td [ A.attribute "data-role" "title" ]
                                [ div [ A.class "flex items-center gap-2" ]
                                    [ span [ A.class ("plan-avatar plan-avatar-sm plan-c-" ++ avatarColor person.id) ] [ text (initials person.name) ]
                                    , span [ A.class "font-medium text-primary-text" ] [ text person.name ]
                                    ]
                                ]
                            , td [ A.class "tnum text-right", A.attribute "data-label" (t model "report.capacity") ] [ text (hoursLabel (toFloat capacity)) ]
                            , td [ A.class "tnum text-right", A.attribute "data-label" (t model "time_off") ] [ text (hoursLabel (toFloat timeOff)) ]
                            , td [ A.class "tnum text-right", A.attribute "data-label" (t model "report.planned") ] [ text (hoursLabel (toFloat work)) ]
                            , td [ A.class "tnum text-right", A.attribute "data-label" (t model "report.planned_to_date") ] [ text (hoursLabel (toFloat workToDate)) ]
                            , td [ A.class "tnum text-right", A.attribute "data-label" (t model "report.tracked") ] [ text (hoursLabel (toFloat done)) ]
                            , td [ A.attribute "data-label" (t model "report.utilization") ] [ viewUtilization available work ]
                            ]
                    )

        projectRowsHtml =
            schedule.projects
                |> List.filter (\project -> matchesSearch model [ project.name, clientName schedule project.clientId ])
                |> List.filterMap
                    (\project ->
                        let
                            plannedOn until =
                                schedule.assignments
                                    |> List.filter (\x -> x.projectId == Just project.id)
                                    |> List.map (\x -> Cal.minutesInRange (assigneeWorkDays model (Just x.assignee)) geo.start until x)
                                    |> List.sum

                            work =
                                plannedOn geo.end

                            workToDate =
                                plannedOn toDate

                            done =
                                tracked (always True) ((==) project.id)
                        in
                        if work == 0 && done == 0 then
                            Nothing

                        else
                            Just
                                (tr []
                                    [ td [ A.attribute "data-role" "title" ]
                                        [ div [ A.class "flex items-center gap-2" ]
                                            [ span [ A.class ("plan-dot plan-c-" ++ project.color) ] []
                                            , span []
                                                [ span [ A.class "block text-xs text-muted-foreground" ] [ text (clientName schedule project.clientId) ]
                                                , span [ A.class "font-medium text-primary-text" ] [ text project.name ]
                                                ]
                                            ]
                                        ]
                                    , td [ A.class "tnum text-right", A.attribute "data-label" (t model "report.planned") ] [ text (hoursLabel (toFloat work)) ]
                                    , td [ A.class "tnum text-right", A.attribute "data-label" (t model "report.planned_to_date") ] [ text (hoursLabel (toFloat workToDate)) ]
                                    , td [ A.class "tnum text-right", A.attribute "data-label" (t model "report.tracked") ] [ text (hoursLabel (toFloat done)) ]
                                    , td [ A.class "tnum text-right", A.attribute "data-label" (t model "report.difference") ]
                                        [ span [ A.classList [ ( "text-destructive-foreground", done > workToDate ), ( "text-success-foreground", done <= workToDate && workToDate > 0 ) ] ]
                                            [ text (signed (toFloat (done - workToDate))) ]
                                        ]
                                    ]
                                )
                    )
    in
    div [ A.class "plan-report" ]
        [ p [ A.class "page-subtitle mb-4" ] [ text (tf model "report.intro" [ ( "range", rangeLabel model ) ]) ]
        , div [ A.class "surface-card overflow-hidden" ]
            [ div [ A.class "plan-report-head" ] [ h2 [ A.class "section-title" ] [ text (t model "report.people") ] ]
            , table [ A.class "table-stack plan-table" ]
                [ thead []
                    [ tr []
                        [ th [] [ text (t model "report.person") ]
                        , th [ A.class "text-right" ] [ text (t model "report.capacity") ]
                        , th [ A.class "text-right" ] [ text (t model "time_off") ]
                        , th [ A.class "text-right" ] [ text (t model "report.planned") ]
                        , th [ A.class "text-right" ] [ text (t model "report.planned_to_date") ]
                        , th [ A.class "text-right" ] [ text (t model "report.tracked") ]
                        , th [ A.class "w-1/5" ] [ text (t model "report.utilization") ]
                        ]
                    ]
                , tbody [] personRows
                ]
            ]
        , div [ A.class "surface-card overflow-hidden mt-6" ]
            [ div [ A.class "plan-report-head" ] [ h2 [ A.class "section-title" ] [ text (t model "report.projects") ] ]
            , if List.isEmpty projectRowsHtml then
                div [ A.class "plan-empty" ] [ text (t model "report.no_projects") ]

              else
                table [ A.class "table-stack plan-table" ]
                    [ thead []
                        [ tr []
                            [ th [] [ text (t model "report.project") ]
                            , th [ A.class "text-right" ] [ text (t model "report.planned") ]
                            , th [ A.class "text-right" ] [ text (t model "report.planned_to_date") ]
                            , th [ A.class "text-right" ] [ text (t model "report.tracked") ]
                            , th [ A.class "text-right" ] [ text (t model "report.difference") ]
                            ]
                        ]
                    , tbody [] projectRowsHtml
                    ]
            ]
        ]


signed : Float -> String
signed minutes =
    if minutes > 0 then
        "+" ++ hoursLabel minutes

    else
        hoursLabel minutes


{-| Planned share of the hours left after time off.
-}
viewUtilization : Int -> Int -> Html Msg
viewUtilization available planned =
    let
        plannedPercent =
            if available <= 0 then
                0

            else
                toFloat planned / toFloat available * 100
    in
    div [ A.class "flex items-center gap-3" ]
        [ div [ A.class "plan-meter" ]
            [ div
                [ A.class "plan-meter-fill"
                , A.classList [ ( "is-over", plannedPercent > 100.5 ) ]
                , A.style "width" (String.fromFloat (min 100 plannedPercent) ++ "%")
                ]
                []
            ]
        , span [ A.class "tnum text-sm text-secondary-text w-12 text-right" ] [ text (String.fromInt (round plannedPercent) ++ "%") ]
        ]



-- EXPORT


exportRange : Model -> Maybe ( Date, Date )
exportRange model =
    let
        monday =
            Date.floor Date.Monday model.today

        sunday date =
            Date.ceiling Date.Sunday date

        monthStart =
            Date.floor Date.Month model.today

        monthEnd =
            Date.add Date.Days -1 (Date.add Date.Months 1 monthStart)

        yearStart =
            Date.floor Date.Year model.today

        yearEnd =
            Date.add Date.Days -1 (Date.add Date.Years 1 yearStart)
    in
    case model.exportForm.timeframe of
        "this_week" ->
            Just ( monday, Date.add Date.Days 6 monday )

        "2_weeks" ->
            Just ( monday, Date.add Date.Days 13 monday )

        "16_weeks" ->
            Just ( monday, Date.add Date.Days 111 monday )

        "this_month" ->
            Just ( Date.floor Date.Monday monthStart, sunday monthEnd )

        "this_year" ->
            Just ( Date.floor Date.Monday yearStart, sunday yearEnd )

        _ ->
            case ( Date.fromIsoString model.exportForm.start, Date.fromIsoString model.exportForm.end ) of
                ( Ok from, Ok to ) ->
                    if Date.compare from to /= GT && Date.diff Date.Days from to <= 400 then
                        Just ( from, to )

                    else
                        Nothing

                _ ->
                    Nothing


viewExport : Model -> Html Msg
viewExport model =
    let
        form =
            model.exportForm

        radio field value key =
            label [ A.class "plan-radio" ]
                [ input
                    [ A.type_ "radio"
                    , A.name field
                    , A.checked
                        (if field == "view" then
                            form.view == value

                         else
                            form.period == value
                        )
                    , E.onCheck (\_ -> UpdateExport field value)
                    ]
                    []
                , text (t model key)
                ]

        href =
            exportRange model
                |> Maybe.map
                    (\( from, to ) ->
                        model.config.basePath
                            ++ "/export.csv"
                            ++ Url.Builder.toQuery
                                [ Url.Builder.string "view" form.view
                                , Url.Builder.string "period" form.period
                                , Url.Builder.string "start" (Date.toIsoString from)
                                , Url.Builder.string "end" (Date.toIsoString to)
                                ]
                    )
    in
    div [ A.class "surface-card plan-export" ]
        [ h2 [ A.class "section-title" ] [ text (t model "export.title") ]
        , p [ A.class "page-subtitle mb-6" ] [ text (t model "export.intro") ]
        , div [ A.class "plan-field" ]
            [ span [ A.class "form-label" ] [ text (t model "export.format") ]
            , div [ A.class "flex gap-4" ] [ radio "view" "projects" "export.projects", radio "view" "team" "export.team" ]
            ]
        , div [ A.class "plan-field" ]
            [ span [ A.class "form-label" ] [ text (t model "export.period") ]
            , div [ A.class "flex gap-4" ] [ radio "period" "weekly" "export.weekly", radio "period" "monthly" "export.monthly" ]
            ]
        , div [ A.class "plan-field" ]
            [ label [ A.class "form-label", A.for "plan-export-timeframe" ] [ text (t model "export.timeframe") ]
            , select [ A.id "plan-export-timeframe", A.class "form-input max-w-xs", E.on "change" (Decode.map (UpdateExport "timeframe") E.targetValue) ]
                (List.map
                    (\( value, key ) -> option [ A.value value, A.selected (form.timeframe == value) ] [ text (t model key) ])
                    [ ( "this_week", "export.this_week" ), ( "2_weeks", "export.two_weeks" ), ( "16_weeks", "export.sixteen_weeks" ), ( "this_month", "export.this_month" ), ( "this_year", "export.this_year" ), ( "custom", "export.custom" ) ]
                )
            ]
        , if form.timeframe == "custom" then
            div [ A.class "plan-field flex gap-3 items-center" ]
                [ input [ A.type_ "date", A.class "form-input max-w-[12rem]", A.value form.start, E.onInput (UpdateExport "start") ] []
                , span [ A.class "text-muted-foreground" ] [ text "–" ]
                , input [ A.type_ "date", A.class "form-input max-w-[12rem]", A.value form.end, E.onInput (UpdateExport "end") ] []
                ]

          else
            text ""
        , case ( href, exportRange model ) of
            ( Just url, Just ( from, to ) ) ->
                div [ A.class "flex items-center gap-4 mt-2" ]
                    [ a [ A.class "plan-button plan-button-primary", A.href url, A.download "" ] [ text (t model "export.download") ]
                    , span [ A.class "text-sm text-muted-foreground tnum" ] [ text (formatDate model from ++ " " ++ String.fromInt (Date.year from) ++ " – " ++ formatDate model to ++ " " ++ String.fromInt (Date.year to)) ]
                    ]

            _ ->
                p [ A.class "form-error" ] [ text (t model "errors.invalid_range") ]
        ]



-- MODALS


viewModal : Model -> Html Msg
viewModal model =
    case ( model.modal, model.schedule ) of
        ( Just modal, Just schedule ) ->
            div [ A.class "plan-modal-backdrop", E.on "click" backdropClick ]
                [ div
                    [ A.class "plan-modal"
                    , A.attribute "role" "dialog"
                    , A.attribute "aria-modal" "true"
                    ]
                    [ case modal of
                        AssignmentModal form ->
                            viewAssignmentForm model schedule form

                        MilestoneModal form ->
                            viewMilestoneForm model schedule form

                        PlaceholderModal form ->
                            viewPlaceholderForm model form

                        PersonModal form ->
                            viewPersonForm model form

                        ProjectModal form ->
                            viewProjectForm model schedule form
                    ]
                ]

        _ ->
            text ""


{-| Close only when the click lands on the backdrop itself. (Stopping
propagation inside the dialog instead would make Elm re-render synchronously
in the middle of a checkbox toggle and undo it.)
-}
backdropClick : Decoder Msg
backdropClick =
    Decode.at [ "target", "className" ] Decode.string
        |> Decode.andThen
            (\className ->
                if className == "plan-modal-backdrop" then
                    Decode.succeed CloseModal

                else
                    Decode.fail "click inside the dialog"
            )


modalHeader : String -> Maybe String -> Html Msg
modalHeader title subtitle =
    div [ A.class "plan-modal-head" ]
        [ div []
            [ h3 [ A.class "text-lg font-semibold text-primary-text" ] [ text title ]
            , case subtitle of
                Just value ->
                    p [ A.class "text-sm text-muted-foreground mt-0.5" ] [ text value ]

                Nothing ->
                    text ""
            ]
        , button [ A.type_ "button", A.class "plan-icon-button", A.attribute "aria-label" "Close", E.onClick CloseModal ] [ text "✕" ]
        ]


viewError : Maybe String -> Html Msg
viewError error =
    case error of
        Just message ->
            div [ A.class "plan-form-error", A.attribute "role" "alert" ] [ text message ]

        Nothing ->
            text ""


formField : String -> List (Html Msg) -> Html Msg
formField title children =
    div [ A.class "plan-field" ] (span [ A.class "form-label" ] [ text title ] :: children)


viewAssignmentForm : Model -> Schedule -> AssignmentForm -> Html Msg
viewAssignmentForm model schedule form =
    let
        readOnly =
            not schedule.canEdit

        assignee =
            T.assigneeFromKey form.assignee

        workDays =
            formWorkDays model form

        hours =
            parseHours form.hours |> Maybe.withDefault 0

        capacityHint =
            case
                assignee
                    |> Maybe.andThen
                        (\x ->
                            case x of
                                PersonAssignee id ->
                                    findPerson model id

                                PlaceholderAssignee _ ->
                                    Nothing
                        )
            of
                Just person ->
                    let
                        daily =
                            Cal.dailyCapacity person.workDays person.capacityMinutes
                    in
                    if daily > 0 then
                        tf model "percent_of_capacity" [ ( "percent", String.fromInt (round (hours * 60 / daily * 100)) ), ( "hours", Cal.formatHours daily ) ]

                    else
                        ""

                Nothing ->
                    ""

        title =
            case ( form.id, readOnly ) of
                ( _, True ) ->
                    t model "assignment.view_title"

                ( Just _, False ) ->
                    t model "assignment.edit_title"

                ( Nothing, False ) ->
                    t model "assignment.new_title"
    in
    Html.form [ E.onSubmit SubmitAssignment, A.novalidate True ]
        [ modalHeader title (assignee |> Maybe.map (assigneeName schedule))
        , div [ A.class "plan-modal-body" ]
            [ viewError form.error
            , formField (t model "assignment.project")
                [ select [ A.class "form-input", A.disabled readOnly, E.on "change" (Decode.map (UpdateAssignment FProject) E.targetValue) ] (projectOptions model schedule form.project) ]
            , formField (t model "assignment.assignee")
                [ select [ A.class "form-input", A.disabled readOnly, E.on "change" (Decode.map (UpdateAssignment FAssignee) E.targetValue) ] (assigneeOptions model schedule form.assignee) ]
            , div [ A.class "grid grid-cols-2 gap-3" ]
                [ formField (t model "assignment.start") [ input [ A.type_ "date", A.class "form-input", A.disabled readOnly, A.value form.start, E.onInput (UpdateAssignment FStart) ] [] ]
                , formField (t model "assignment.end") [ input [ A.type_ "date", A.class "form-input", A.disabled readOnly, A.value form.end, E.onInput (UpdateAssignment FEnd) ] [] ]
                ]
            , div [ A.class "grid grid-cols-2 gap-3" ]
                [ formField (t model "assignment.hours_per_day")
                    [ input [ A.type_ "number", A.step "0.25", A.min "0.25", A.max "24", A.class "form-input tnum", A.disabled readOnly, A.value form.hours, E.onInput (UpdateAssignment FHours) ] []
                    , span [ A.class "plan-hint" ] [ text capacityHint ]
                    ]
                , formField (t model "assignment.total")
                    [ input
                        [ A.type_ "number"
                        , A.step "0.25"
                        , A.min "0"
                        , A.class "form-input tnum"
                        , A.disabled readOnly
                        , A.value (Cal.formatHours (hours * 60 * toFloat workDays))
                        , E.onInput (UpdateAssignment FTotal)
                        ]
                        []
                    , span [ A.class "plan-hint" ] [ text (tf model "across_days" [ ( "days", String.fromInt workDays ) ]) ]
                    ]
                ]
            , formField (t model "assignment.notes")
                [ textarea [ A.class "form-input", A.rows 2, A.disabled readOnly, A.value form.notes, A.placeholder (t model "assignment.notes_placeholder"), E.onInput (UpdateAssignment FNotes) ] [] ]
            , if form.id == Nothing && not readOnly then
                div [ A.class "plan-field flex items-center gap-2 flex-wrap" ]
                    [ label [ A.class "plan-check" ]
                        [ input [ A.type_ "checkbox", A.class "form-checkbox", A.checked form.repeat, E.onCheck SetRepeat ] []
                        , text (t model "assignment.repeat")
                        ]
                    , if form.repeat then
                        span [ A.class "flex items-center gap-2 text-sm text-secondary-text" ]
                            [ text (t model "assignment.repeat_for")
                            , input [ A.type_ "number", A.min "1", A.max "52", A.class "form-input w-20 tnum", A.value form.repeatWeeks, E.onInput (UpdateAssignment FRepeatWeeks) ] []
                            , text (t model "assignment.weeks")
                            ]

                      else
                        text ""
                    ]

              else
                text ""
            , case form.id of
                Just id ->
                    if not readOnly && form.start /= form.end then
                        div [ A.class "plan-split" ]
                            [ span [ A.class "text-sm text-secondary-text" ] [ text (t model "assignment.split_at") ]
                            , input [ A.type_ "date", A.class "form-input w-44", A.value form.splitDate, E.onInput (UpdateAssignment FSplitDate) ] []
                            , button [ A.type_ "button", A.class "plan-button", E.onClick (SplitAssignment id) ] [ text (t model "assignment.split") ]
                            ]

                    else
                        text ""

                Nothing ->
                    text ""
            ]
        , div [ A.class "plan-modal-foot" ]
            (if readOnly then
                [ button [ A.type_ "button", A.class "plan-button", E.onClick CloseModal ] [ text (t model "close") ] ]

             else
                [ case form.id of
                    Just id ->
                        if form.confirmDelete then
                            button [ A.type_ "button", A.class "plan-button plan-button-danger", E.onClick (DeleteAssignment id) ] [ text (t model "confirm_delete") ]

                        else
                            button [ A.type_ "button", A.class "plan-button plan-button-ghost-danger", E.onClick AskDeleteAssignment ] [ text (t model "delete") ]

                    Nothing ->
                        span [] []
                , div [ A.class "flex gap-2" ]
                    [ button [ A.type_ "button", A.class "plan-button", E.onClick CloseModal ] [ text (t model "cancel") ]
                    , button [ A.type_ "submit", A.class "plan-button plan-button-primary", A.disabled form.saving ] [ text (t model "assignment.save") ]
                    ]
                ]
            )
        ]


viewMilestoneForm : Model -> Schedule -> MilestoneForm -> Html Msg
viewMilestoneForm model schedule form =
    Html.form [ E.onSubmit SubmitMilestone, A.novalidate True ]
        [ modalHeader
            (if form.id == Nothing then
                t model "milestone.new_title"

             else
                t model "milestone.edit_title"
            )
            (findProject schedule form.projectId |> Maybe.map .name)
        , div [ A.class "plan-modal-body" ]
            [ viewError form.error
            , formField (t model "milestone.name") [ input [ A.class "form-input", A.value form.name, A.placeholder (t model "milestone.name_placeholder"), A.autofocus True, E.onInput UpdateMilestoneName ] [] ]
            , formField (t model "milestone.date") [ input [ A.type_ "date", A.class "form-input", A.value form.date, E.onInput UpdateMilestoneDate ] [] ]
            ]
        , div [ A.class "plan-modal-foot" ]
            [ case form.id of
                Just id ->
                    button [ A.type_ "button", A.class "plan-button plan-button-ghost-danger", E.onClick (DeleteMilestone id) ] [ text (t model "delete") ]

                Nothing ->
                    span [] []
            , div [ A.class "flex gap-2" ]
                [ button [ A.type_ "button", A.class "plan-button", E.onClick CloseModal ] [ text (t model "cancel") ]
                , button [ A.type_ "submit", A.class "plan-button plan-button-primary", A.disabled form.saving ] [ text (t model "milestone.save") ]
                ]
            ]
        ]


viewPlaceholderForm : Model -> PlaceholderForm -> Html Msg
viewPlaceholderForm model form =
    Html.form [ E.onSubmit SubmitPlaceholder, A.novalidate True ]
        [ modalHeader
            (if form.id == Nothing then
                t model "placeholder_form.new_title"

             else
                t model "placeholder_form.edit_title"
            )
            (Just (t model "placeholder_form.tip"))
        , div [ A.class "plan-modal-body" ]
            [ viewError form.error
            , formField (t model "placeholder_form.name") [ input [ A.class "form-input", A.value form.name, A.placeholder (t model "placeholder_form.name_placeholder"), A.autofocus True, E.onInput UpdatePlaceholderName ] [] ]
            , formField (t model "placeholder_form.roles") [ input [ A.class "form-input", A.value form.roles, A.placeholder (t model "placeholder_form.roles_placeholder"), E.onInput UpdatePlaceholderRoles ] [] ]
            ]
        , div [ A.class "plan-modal-foot" ]
            [ case form.id of
                Just id ->
                    if form.confirmDelete then
                        button [ A.type_ "button", A.class "plan-button plan-button-danger", E.onClick (DeletePlaceholder id) ] [ text (t model "confirm_delete") ]

                    else
                        button [ A.type_ "button", A.class "plan-button plan-button-ghost-danger", E.onClick AskDeletePlaceholder ] [ text (t model "delete") ]

                Nothing ->
                    span [] []
            , div [ A.class "flex gap-2" ]
                [ button [ A.type_ "button", A.class "plan-button", E.onClick CloseModal ] [ text (t model "cancel") ]
                , button [ A.type_ "submit", A.class "plan-button plan-button-primary", A.disabled form.saving ] [ text (t model "placeholder_form.save") ]
                ]
            ]
        ]


viewPersonForm : Model -> PersonForm -> Html Msg
viewPersonForm model form =
    let
        perDay =
            parseHours form.hours
                |> Maybe.map (\hours -> Cal.dailyCapacity form.workDays (round (hours * 60)))
                |> Maybe.withDefault 0
    in
    Html.form [ E.onSubmit SubmitPerson, A.novalidate True ]
        [ modalHeader form.person.name (Just form.person.email)
        , div [ A.class "plan-modal-body" ]
            [ viewError form.error
            , formField (t model "person.capacity")
                [ div [ A.class "flex items-center gap-2" ]
                    [ input [ A.type_ "number", A.step "0.5", A.min "0", A.max "168", A.class "form-input w-28 tnum", A.value form.hours, E.onInput UpdatePersonHours ] []
                    , span [ A.class "text-sm text-secondary-text" ] [ text (t model "person.hours_per_week") ]
                    ]
                ]
            , formField (t model "person.work_days")
                [ div [ A.class "flex gap-1.5" ]
                    (List.indexedMap
                        (\bit name ->
                            let
                                on =
                                    modBy 2 (form.workDays // (2 ^ bit)) == 1
                            in
                            button
                                [ A.type_ "button"
                                , A.class "plan-day-toggle"
                                , A.classList [ ( "is-on", on ) ]
                                , A.attribute "aria-pressed" (boolString on)
                                , A.title name
                                , E.onClick (TogglePersonDay bit)
                                ]
                                [ text (String.left 2 name) ]
                        )
                        model.i18n.weekdays
                    )
                , span [ A.class "plan-hint" ] [ text (tf model "person.per_day" [ ( "hours", Cal.formatHours perDay ) ]) ]
                ]
            ]
        , div [ A.class "plan-modal-foot" ]
            [ span [] []
            , div [ A.class "flex gap-2" ]
                [ button [ A.type_ "button", A.class "plan-button", E.onClick CloseModal ] [ text (t model "cancel") ]
                , button [ A.type_ "submit", A.class "plan-button plan-button-primary", A.disabled form.saving ] [ text (t model "person.save") ]
                ]
            ]
        ]


viewProjectForm : Model -> Schedule -> ProjectForm -> Html Msg
viewProjectForm model schedule form =
    div []
        [ modalHeader form.project.name (Just (clientName schedule form.project.clientId))
        , div [ A.class "plan-modal-body" ]
            [ viewError form.error
            , formField (t model "project.color")
                [ div [ A.class "flex flex-wrap gap-2" ]
                    (List.map
                        (\color ->
                            button
                                [ A.type_ "button"
                                , A.class ("plan-swatch plan-c-" ++ color)
                                , A.classList [ ( "is-selected", form.project.color == color ) ]
                                , A.title (t model ("colors." ++ color))
                                , A.attribute "aria-label" (t model ("colors." ++ color))
                                , E.onClick (ChooseColor form.project.id color)
                                ]
                                []
                        )
                        colors
                    )
                ]
            , formField (t model "project.milestones")
                [ button [ A.type_ "button", A.class "plan-button", E.onClick (NewMilestone form.project.id (defaultStart model)) ] [ text ("+ " ++ t model "milestone.new_title") ]
                , span [ A.class "plan-hint" ] [ text (t model "project.milestone_hint") ]
                ]
            , div [ A.class "plan-shift" ]
                [ h3 [ A.class "text-sm font-semibold text-primary-text" ] [ text (t model "project.shift_title") ]
                , p [ A.class "text-sm text-muted-foreground mb-3" ] [ text (t model "project.shift_intro") ]
                , Html.form [ A.class "flex items-end gap-3 flex-wrap", E.onSubmit SubmitShift, A.novalidate True ]
                    [ div []
                        [ span [ A.class "form-label" ] [ text (t model "project.shift_from") ]
                        , input [ A.type_ "date", A.class "form-input w-44", A.value form.shiftFrom, E.onInput UpdateShiftFrom ] []
                        ]
                    , div []
                        [ span [ A.class "form-label" ] [ text (t model "project.shift_to") ]
                        , input [ A.type_ "date", A.class "form-input w-44", A.value form.shiftTo, E.onInput UpdateShiftTo ] []
                        ]
                    , button [ A.type_ "submit", A.class "plan-button plan-button-primary", A.disabled form.saving ] [ text (t model "project.shift") ]
                    ]
                ]
            ]
        , div [ A.class "plan-modal-foot" ]
            [ span [] []
            , button [ A.type_ "button", A.class "plan-button", E.onClick CloseModal ] [ text (t model "close") ]
            ]
        ]


viewToast : Model -> Html Msg
viewToast model =
    case model.toast of
        Just { id, kind, message } ->
            div
                [ A.class "plan-toast"
                , A.classList [ ( "is-error", kind == Failure ) ]
                , A.attribute "role" "status"
                , E.onClick (DismissToast id)
                ]
                [ text message ]

        Nothing ->
            text ""
