with source as (
    select * from {{ ref('raw_transactions') }}
),

renamed as (
    select
        transaction_id,
        player_id,
        title_id,
        platform                                as platform_id,

        -- Source arrives in America/New_York wall-clock; bring it onto UTC like every
        -- other feed. Keep the raw local timestamp too for auditability.
        cast(transaction_at as timestamp_ntz)   as transaction_at_local,
        {{ to_utc('transaction_at') }}          as transaction_at,

        transaction_type,
        nullif(trim(sku_id), '')                as sku_id,
        cast(gross_amount_usd as number(12,2))  as gross_amount_usd,
        cast(platform_fee_usd as number(12,2))  as platform_fee_usd,
        currency_code,
        cast(local_amount as number(14,2))      as local_amount,
        payment_method,
        cast(is_first_purchase as boolean)      as is_first_purchase,
        cast(_loaded_at as timestamp_ntz)       as loaded_at
    from source
)

select * from renamed
