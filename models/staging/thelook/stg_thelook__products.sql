with source as (
    select * from {{ source('thelook', 'products') }}
),

renamed as (
    select 
        id as product_id,
        category as product_category,
        name as product_name,
        brand as product_brand,
        department as product_department,
        cost as product_cost_usd,
        retail_price as product_retail_price_usd,
        sku as product_sku,
        distribution_center_id
    from source
)

select * from renamed