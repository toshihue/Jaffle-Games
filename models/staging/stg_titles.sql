with
    source as (select * from {{ ref("raw_titles") }}),

    renamed as (
        select
            title_id,
            trim(title_name) as title_name,
            trim(genre) as genre,
            trim(sub_genre) as sub_genre,
            monetization_model,
            cast(launch_date as date) as launch_date,
            cast(list_price_usd as number(10, 2)) as list_price_usd,
            trim(internal_team) as internal_team,
            trim(engine) as engine,
            esrb_rating,
            cast(is_live_service as boolean) as is_live_service,
            cast(sunset_date as date) as sunset_date,
            cast(_loaded_at as timestamp_ntz) as loaded_at
        from source
    )

select *
from renamed
