with source as (
    select * from {{ source('thelook', 'orders') }}
),

renamed as (
    Select 
        order_id,
        user_id,
        status as order_status,
        gender as customer_gender,
        created_at as order_created_at,
        returned_at as order_returned_at,
        shipped_at as order_shipped_at,
        delivered_at as order_delivered_at,
        num_of_item as order_item_count,
        current_timestamp() as dbt_loaded_at
    from source
)

select * from renamed