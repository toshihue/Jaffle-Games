-- Business rule: studio net revenue at the month grain must never be negative — a month where
-- refunds outweigh all sales would signal a data or recognition problem. Passes with no rows.

select
    transaction_month,
    sum(net_amount_usd) as net_revenue_usd
from {{ ref('fct_transactions') }}
group by 1
having sum(net_amount_usd) < 0
