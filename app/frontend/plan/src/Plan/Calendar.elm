module Plan.Calendar exposing
    ( countWorkDays
    , covers
    , dailyCapacity
    , daysBetween
    , formatHours
    , isWorkDay
    , minutesInRange
    , overlaps
    , workDaysPerWeek
    )

{-| Date arithmetic for the schedule. Working days are a bitmask where bit 0 is
Monday and bit 6 is Sunday, matching `access_infos.plan_work_days`.
-}

import Date exposing (Date)


isWorkDay : Int -> Date -> Bool
isWorkDay mask date =
    modBy 2 (mask // (2 ^ (Date.weekdayNumber date - 1))) == 1


workDaysPerWeek : Int -> Int
workDaysPerWeek mask =
    List.range 0 6
        |> List.filter (\bit -> modBy 2 (mask // (2 ^ bit)) == 1)
        |> List.length


{-| Minutes of capacity on one working day, from a weekly capacity.
-}
dailyCapacity : Int -> Int -> Float
dailyCapacity mask weeklyMinutes =
    case workDaysPerWeek mask of
        0 ->
            0

        days ->
            toFloat weeklyMinutes / toFloat days


{-| Inclusive number of days from the first to the second date.
-}
daysBetween : Date -> Date -> Int
daysBetween from to =
    Date.diff Date.Days from to + 1


countWorkDays : Int -> Date -> Date -> Int
countWorkDays mask from to =
    if Date.compare from to == GT then
        0

    else
        Date.range Date.Day 1 from (Date.add Date.Days 1 to)
            |> List.filter (isWorkDay mask)
            |> List.length


covers : { a | startDate : Date, endDate : Date } -> Date -> Bool
covers { startDate, endDate } date =
    Date.isBetween startDate endDate date


overlaps : Date -> Date -> { a | startDate : Date, endDate : Date } -> Bool
overlaps from to { startDate, endDate } =
    Date.compare startDate to /= GT && Date.compare endDate from /= LT


{-| Minutes an assignment contributes between two dates (inclusive), counting
only the assignee's working days.
-}
minutesInRange : Int -> Date -> Date -> { a | startDate : Date, endDate : Date, minutesPerDay : Int } -> Int
minutesInRange mask from to assignment =
    let
        start =
            Date.max from assignment.startDate

        end =
            Date.min to assignment.endDate
    in
    countWorkDays mask start end * assignment.minutesPerDay


{-| 90 -> "1.5", 480 -> "8", 20 -> "0.33"
-}
formatHours : Float -> String
formatHours minutes =
    let
        hundredths =
            round (minutes / 60 * 100)

        whole =
            abs hundredths // 100

        fraction =
            modBy 100 (abs hundredths)

        sign =
            if hundredths < 0 then
                "-"

            else
                ""
    in
    if fraction == 0 then
        sign ++ String.fromInt whole

    else if modBy 10 fraction == 0 then
        sign ++ String.fromInt whole ++ "." ++ String.fromInt (fraction // 10)

    else
        sign ++ String.fromInt whole ++ "." ++ String.padLeft 2 '0' (String.fromInt fraction)
