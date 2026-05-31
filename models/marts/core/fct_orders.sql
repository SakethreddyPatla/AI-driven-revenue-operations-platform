with orders as (
    select * from {{ ref('stg_thelook__orders') }}
),

order_items as (
    select * from {{ ref('dim_order_items') }}
),

-- aggregate item-level metrics up to order level
order_metrics as (
    select
        order_id,
        count(order_item_id)                        as order_item_count,
        round(sum(item_sale_price_usd), 2)          as order_revenue_usd,
        round(sum(inventory_cost_usd), 2)           as order_cost_usd,
        round(sum(item_gross_margin_usd), 2)        as order_gross_margin_usd,
        countif(item_status = 'Returned')           as returned_item_count
    from order_items
    group by order_id
),

final as (
    select
        -- primary key
        o.order_id,

        -- foreign keys (the "spokes" of the star)
        o.user_id,
        cast(
            format_date('%Y%m%d', date(o.order_created_at))
            as int64
        )                                           as date_id,

        -- order attributes
        o.order_status,
        o.customer_gender,

        -- metrics (all aggregated at order grain)
        m.order_item_count,
        m.order_revenue_usd,
        m.order_cost_usd,
        m.order_gross_margin_usd,
        m.returned_item_count,

        -- derived
        round(
            safe_divide(m.order_gross_margin_usd, m.order_revenue_usd) * 100, 2
        )                                           as order_margin_pct,

        case
            when m.returned_item_count > 0 then true
            else false
        end                                         as has_return,

        -- timestamps
        o.order_created_at,
        o.order_shipped_at,
        o.order_delivered_at,
        o.order_returned_at

    from orders o
    left join order_metrics m
        on o.order_id = m.order_id
)

select * from final