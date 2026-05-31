with orders as (
    select * from {{ ref('fct_orders') }}
),

dates as (
    select * from {{ ref('dim_dates') }}
),

quaterly as (
    select 
        d.year,
        d.quarter,
        d.quarter_label,
        count(distinct o.order_id) as total_orders,
        count(distinct o.user_id) as unique_customers,
        round(sum(o.order_revenue_usd), 2) as total_revenue_usd,
        round(sum(o.order_gross_margin_usd), 2) as total_margin_usd,
        round(avg(o.order_revenue_usd), 2) as avg_order_value_usd,
        round(avg(o.order_margin_pct), 2) as avg_margin_pct,
        countif(o.has_return = true) as order_with_returns,
        round(
            safe_divide(
                countif(o.has_return = true),
                count(distinct o.order_id)
            ) * 100, 2
        ) as return_rate_pct
    from orders o
    left join dates d 
        on o.date_id = d.date_id
    where d.year is not null
    group by d.year,
        d.quarter,
        d.quarter_label
),

with_growth as (
    select
        *,
        lag(total_revenue_usd) over (order by year, quarter) as prev_quater_revenue_usd,
        round(
            safe_divide(
                total_revenue_usd - lag(total_revenue_usd) over (order by year, quarter),
                lag(total_revenue_usd) over (order by year, quarter)
            ) * 100, 2
        ) as revenue_growth_pct,
        round(
            avg_margin_pct - lag(avg_margin_pct) over (
                order by year, quarter
            ), 2
        ) as margin_change_pp
    from quaterly
)
select * from with_growth
order by year, quarter