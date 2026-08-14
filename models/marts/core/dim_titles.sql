-- One row per title, enriched with lifecycle stage. Stage is derived from age plus
-- recent
-- engagement so the underperformer surfaces as a sunset_candidate and the aging premium
-- back-catalogue surfaces as declining. Thresholds come from project vars.
with
    titles as (select * from {{ ref("stg_titles") }}),

    activity as (select * from {{ ref("int_title_activity") }}),

    platform_rollup as (
        select
            title_id,
            count(*) as platform_count,
            min(platform_launch_date) as earliest_platform_launch_date
        from {{ ref("stg_title_platforms") }}
        group by 1
    ),

    joined as (
        select
            titles.*,
            activity.lifetime_sessions,
            activity.lifetime_players,
            activity.first_session_at,
            activity.last_session_at,
            activity.sessions_last_60d,
            activity.active_players_last_90d,
            activity.days_since_last_session,
            activity.avg_review_rating,
            activity.review_count,
            activity.recommend_rate,
            platform_rollup.platform_count,
            platform_rollup.earliest_platform_launch_date,
            datediff(
                'day',
                titles.launch_date,
                cast('{{ var("analysis_as_of_date") }}' as date)
            ) as days_since_launch
        from titles
        left join activity using (title_id)
        left join platform_rollup using (title_id)
    )

select
    title_id::varchar as title_id,
    title_name::varchar as title_name,
    genre::varchar as genre,
    sub_genre::varchar as sub_genre,
    monetization_model::varchar as monetization_model,
    is_live_service::boolean as is_live_service,
    launch_date::date as launch_date,
    list_price_usd::number(12, 2) as list_price_usd,
    internal_team::varchar as internal_team,
    engine::varchar as engine,
    esrb_rating::varchar as esrb_rating,
    sunset_date::date as sunset_date,
    days_since_launch::integer as days_since_launch,
    coalesce(platform_count, 0)::integer as platform_count,
    earliest_platform_launch_date::date as earliest_platform_launch_date,

    -- Lifecycle stage. Order matters: launch first, then the sunset test, then
    -- activity.
    (
        case
            when days_since_launch <= 90
            then 'launch_window'
            when
                coalesce(days_since_last_session, 9999) > 60 and days_since_launch > 365
            then 'sunset_candidate'
            when days_since_launch <= 365
            then 'growth'
            when
                coalesce(active_players_last_90d, 0)
                >= {{ var("min_active_players_threshold") }}
            then 'mature'
            else 'declining'
        end
    )::varchar as lifecycle_stage,

    coalesce(lifetime_sessions, 0)::integer as lifetime_sessions,
    coalesce(lifetime_players, 0)::integer as lifetime_players,
    first_session_at::timestamp_ntz as first_session_at,
    last_session_at::timestamp_ntz as last_session_at,
    days_since_last_session::integer as days_since_last_session,
    coalesce(sessions_last_60d, 0)::integer as sessions_last_60d,
    coalesce(active_players_last_90d, 0)::integer as active_players_last_90d,
    round(avg_review_rating, 2)::number(4, 2) as avg_review_rating,
    coalesce(review_count, 0)::integer as review_count,
    round(recommend_rate, 4)::number(5, 4) as recommend_rate
from joined
