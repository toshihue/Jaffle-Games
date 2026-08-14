with
    source as (select * from {{ ref("raw_skus") }}),

    renamed as (
        select
            sku_id,
            title_id,
            trim(sku_name) as sku_name,
            sku_category,
            cast(price_usd as number(10, 2)) as price_usd,
            cast(is_active as boolean) as is_active,
            cast(first_available_date as date) as first_available_date
        from source
    )

select *
from renamed
