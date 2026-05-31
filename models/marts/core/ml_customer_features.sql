with orders as (
    select * from {{ ref('fct_orders') }}
),

customers as (
    select * from {{ ref('dim_customers') }}
),

params as (
    select
        date('2022-01-01') as prediction_date,
        date('2019-01-01') as observation_start
),
observation_orders as (
    select
        o.user_id,
        o.order_id,
        o.order_revenue_usd,
        o.order_gross_margin_usd,
        o.has_return,
        o.order_status,
        date(o.order_created_at) as order_date
    from orders o, params p 
    where date(o.order_created_at) between p.observation_start and p.prediction_date
),

future_purchase as(
    select 
        distinct user_id,
        true as purchased_in_next_30_days
    from orders o, params p
    where date(o.order_created_at) > p.prediction_date
        and date(o.order_created_at) <= date_add(p.prediction_date, interval 365 day)
),

customer_featurese as (
    select
        user_id,
        date_diff(
            date('2022-01-01'),
            max(order_date),
            day
        ) as days_since_last_order,

        -- frequency
        count(distinct order_id) as total_orders,
        count(distinct order_date) as distinct_order_dates,

        -- monetary
        round(sum(order_revenue_usd), 2) as lifetime_revenue_usd,
        round(avg(order_revenue_usd), 2) as avg_order_value_usd,
        round(max(order_revenue_usd), 2) as max_order_value_usd,

        -- quality signals
        round(avg(order_gross_margin_usd), 2) as avg_order_margin_usd,
        countif(has_return = true) as total_returns,
        round(
            safe_divide(
                countif(has_return = true),
                count(distinct order_id)
            ), 4
        ) as return_rate,

        -- Recency
        countif(
            order_date >= date_sub(date('2022-01-01'), interval 30 day) 
        ) as orders_last_30_days,

        countif(
            order_date >= date_sub(date('2022-01-01'), interval 90 day)
        ) as orders_last_90_days
    from observation_orders
    group by user_id
),

final as (
    select
        cf.user_id,
        coalesce(fp.purchased_in_next_30_days, false) as purchased_in_next_30_days,
        cf.days_since_last_order,
        cf.total_orders,
        cf.distinct_order_dates,
        cf.lifetime_revenue_usd,
        cf.avg_order_value_usd,
        cf.max_order_value_usd,
        cf.avg_order_margin_usd,
        cf.total_returns,
        cf.return_rate,
        cf.orders_last_30_days,
        cf.orders_last_90_days,

        c.age,
        c.gender,
        c.country,
        c.traffic_source,
        c.age_band
    from customer_featurese cf
    left join customers c
        on cf.user_id = c.user_id
    left join future_purchase fp
        on cf.user_id = fp.user_id
)
select * from final