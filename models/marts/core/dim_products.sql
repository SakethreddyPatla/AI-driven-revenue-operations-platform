with products as (
    select * from {{ ref('stg_thelook__products') }}
),

final as (
    select
        product_id,
        product_category,
        product_name,
        product_brand,
        product_department,
        product_cost_usd,
        product_retail_price_usd,
        product_sku,
        round(product_retail_price_usd - product_cost_usd, 2) as product_gross_margin_usd,
        round(safe_divide(product_retail_price_usd - product_cost_usd, product_retail_price_usd) * 100, 2) as product_gross_margin_pct,
        distribution_center_id
    from products
)

select * from final