-- Date spine covering the 12-month history window plus 90 days forward, so marts can
-- join
-- to a complete calendar (including months/weeks with zero activity). Bounds come from
-- project vars — no hardcoded dates in the model body.
with
    spine as (
        {{
            dbt_utils.date_spine(
                datepart="day",
                start_date="cast('" ~ var("window_start_date") ~ "' as date)",
                end_date="cast('" ~ var("date_spine_end_date") ~ "' as date)",
            )
        }}
    )

select
    cast(date_day as date) as date_day,
    cast(extract(yearfromdate_day) as integer) as year_number,
    cast(extract(quarterfromdate_day) as integer) as quarter_number,
    cast(extract(monthfromdate_day) as integer) as month_number,
    cast(monthname(date_day) as varchar) as month_name,
    cast(extract(dayfromdate_day) as integer) as day_of_month,
    cast(dayofweekiso(date_day) as integer) as day_of_week_iso,
    cast(dayname(date_day) as varchar) as day_name,
    cast((dayofweekiso(date_day)in(6,7)) as boolean) as is_weekend,
    cast(date_trunc('week', date_day) as date) as week_start_date,
    cast(date_trunc('month', date_day) as date) as month_start_date,
    cast(date_trunc('quarter', date_day) as date) as quarter_start_date,
    (
        date_day between cast('{{ var("window_start_date") }}' as date) and cast(
            '{{ var("window_end_date") }}' as date
        )
    )::boolean as is_within_history_window
from spine
