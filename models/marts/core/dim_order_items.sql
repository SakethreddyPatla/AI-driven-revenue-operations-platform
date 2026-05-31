with order_items as (
    select * from {{ ref('stg_thelook__order_items') }}
),

inventory as (
    select * from {{ ref('stg_thelook__inventory_items') }}
),

final as (
    select
        oi.order_item_id,
        oi.order_id,
        oi.user_id,
        oi.product_id,   
        oi.item_status,
        oi.item_sale_price_usd,
        inv.inventory_cost_usd,
        round(
            oi.item_sale_price_usd - inv.inventory_cost_usd, 2
        ) as item_gross_margin_usd,

        oi.item_created_at,
        oi.item_shipped_at,
        oi.item_delivered_at,
        oi.item_returned_at
    from order_items oi
    left join inventory inv 
        on oi.inventory_item_id = inv.inventory_item_id
)

select * from final