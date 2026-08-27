with platforms as (select * from {{ ref("stg_platforms") }})

select
    platform_id::varchar as platform_id,
    platform_family::varchar as platform_family,
    storefront_fee_rate as storefront_fee_rate,
    {{ calculate_additional_fee(2) }} as fee_addition
from platforms
