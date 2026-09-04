{{ config(
    materialized='table'
) }}
with
    source as (select * from {{ ref("raw_platforms") }}),

    renamed as (
        select
            platform as platform_id,
            platform_family as platform_family,
            storefront_fee_rate + 4 as storefront_fee_rate
        from source
    )

select *
from renamed
