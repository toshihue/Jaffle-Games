with
    source as (select * from {{ ref("raw_marketing_spend") }}),

    renamed as (
        select
            campaign_id,
            title_id,
            lower(replace(trim(channel), ' ', '_')) as channel,
            cast(week_start_date as date) as week_start_date,
            cast(spend_usd as number(12, 2)) as spend_usd,
            cast(impressions as integer) as impressions,
            cast(clicks as integer) as clicks,
            cast(installs as integer) as installs
        from source
    )

select *
from renamed
