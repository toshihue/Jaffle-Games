with
    source as (select * from {{ ref("raw_platforms") }}),

    renamed as (
        select
            platform as platform_id,
            platform_family,
            cast(storefront_fee_rate as number(4, 3)) + 4 as storefront_fee_rate
        from source
    )

select *
from renamed
