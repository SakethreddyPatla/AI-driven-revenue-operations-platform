with source as (
    select * from {{ source('thelook', 'order_items') }}
),
renamed as (
    select 
        id as order_item_id,
        order_id,
        user_id,
        product_id,
        inventory_item_id,
        status as item_status,
        created_at as item_created_at,
        shipped_at as item_shipped_at,
        delivered_at as item_delivered_at,
        returned_at as item_returned_at,
        sale_price as item_sale_price_usd,
    from source
)

select * from renamed