-- One row per player with lifecycle attributes. Combines cleaned source attributes with the
-- engagement rollup (int_player_activity) and monetization rollup (int_player_spend).
-- Behavioural churn (is_churned) is defined on session recency; account_status is the
-- source-system state and can differ (e.g. banned cheaters).

with players as (
    select * from {{ ref('stg_players') }}
),

activity as (
    select * from {{ ref('int_player_activity') }}
),

spend as (
    select * from {{ ref('int_player_spend') }}
),

favorite as (
    select p.player_id, a.favorite_title_id, t.title_name as favorite_title_name
    from players p
    left join activity a using (player_id)
    left join {{ ref('stg_titles') }} t on a.favorite_title_id = t.title_id
),

joined as (
    select
        players.*,
        activity.lifetime_sessions,
        activity.lifetime_valid_sessions,
        activity.lifetime_play_minutes,
        activity.distinct_titles_played,
        activity.first_session_at,
        activity.last_session_at,
        activity.primary_platform_id,
        favorite.favorite_title_id,
        favorite.favorite_title_name,
        spend.live_service_net_usd,
        spend.lifetime_net_revenue_usd,
        spend.lifetime_studio_net_usd,
        spend.premium_net_usd,
        spend.payer_segment,
        spend.is_payer,
        spend.first_purchase_at,
        datediff('day', activity.last_session_at, cast('{{ var("analysis_as_of_date") }}' as date)) as days_since_last_session
    from players
    left join activity using (player_id)
    left join spend    using (player_id)
    left join favorite using (player_id)
)

select
    player_id::varchar                              as player_id,
    registered_at::timestamp_ntz                    as registered_at,
    cast(date_trunc('month', registered_at) as date) as registration_cohort_month,
    country_code::varchar                           as country_code,
    platform_registered_on_id::varchar              as platform_registered_on_id,
    acquisition_channel::varchar                    as acquisition_channel,
    acquisition_campaign_id::varchar                as acquisition_campaign_id,
    birth_year::integer                             as birth_year,
    (extract(year from cast('{{ var("analysis_as_of_date") }}' as date)) - birth_year)::integer as age_years,
    marketing_opt_in::boolean                       as marketing_opt_in,
    account_status::varchar                         as account_status,
    last_login_at::timestamp_ntz                    as last_login_at,

    coalesce(lifetime_sessions, 0)::integer         as lifetime_sessions,
    coalesce(lifetime_valid_sessions, 0)::integer   as lifetime_valid_sessions,
    round(coalesce(lifetime_play_minutes, 0), 2)::number(12,2) as lifetime_play_minutes,
    coalesce(distinct_titles_played, 0)::integer    as distinct_titles_played,
    first_session_at::timestamp_ntz                 as first_session_at,
    last_session_at::timestamp_ntz                  as last_session_at,
    days_since_last_session::integer                as days_since_last_session,

    favorite_title_id::varchar                      as favorite_title_id,
    favorite_title_name::varchar                    as favorite_title_name,
    primary_platform_id::varchar                    as primary_platform_id,

    round(coalesce(live_service_net_usd, 0), 2)::number(12,2)     as live_service_net_usd,
    round(coalesce(lifetime_net_revenue_usd, 0), 2)::number(12,2) as lifetime_net_revenue_usd,
    round(coalesce(lifetime_studio_net_usd, 0), 2)::number(12,2)  as lifetime_studio_net_usd,
    coalesce(payer_segment, 'non_payer')::varchar   as payer_segment,
    coalesce(is_payer, false)::boolean              as is_payer,
    first_purchase_at::timestamp_ntz                as first_purchase_at,

    -- Behavioural churn: no session within the churn window as of the analysis date.
    (coalesce(days_since_last_session, 99999) > {{ var('churn_days_threshold') }})::boolean as is_churned
from joined
