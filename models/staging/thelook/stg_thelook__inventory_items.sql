with source as (
    select * from {{ source('thelook', 'inventory_items') }}
),

renamed as (
    select 
        id as inventory_item_id,
        product_id,
        product_category,
        product_name,
        product_brand,
        product_department,
        cost as inventory_cost_usd,
        created_at as inventory_created_at,
        sold_at as inventory_sold_at
    from source
)
select * from renamed