-- One row per player and UTC calendar day. This fact preserves the daily grain
-- required for the engaged-player definition: at least one hour of valid play.
with sessions as (
    select
        player_id,
        session_date,
        session_id,
        is_valid_session,
        session_duration_minutes
    from {{ ref('fct_play_sessions') }}
),

daily_activity as (
    select
        player_id,
        session_date,
        count(*) as session_count,
        count_if(is_valid_session) as valid_session_count,
        coalesce(
            sum(case when is_valid_session then session_duration_minutes else 0 end),
            0
        ) as play_minutes
    from sessions
    group by 1, 2
)

select
    concat(player_id, '-', to_varchar(session_date, 'YYYY-MM-DD'))::varchar
        as player_activity_id,
    player_id::varchar as player_id,
    session_date::date as activity_date,
    session_count::integer as session_count,
    valid_session_count::integer as valid_session_count,
    play_minutes::number(12, 2) as play_minutes,
    (play_minutes >= {{ var('engaged_player_min_daily_play_minutes') }})::boolean
        as is_engaged_player
from daily_activity
