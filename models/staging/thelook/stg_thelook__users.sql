with source as (
    select * from {{ source('thelook', 'users') }}
),
renamed as (
    select
        id as user_id,
        first_name,
        last_name,
        email,
        age,
        gender,
        postal_code,
        city,
        state,
        country,
        traffic_source,
        created_at as user_created_at
    from source
)
select * from renamed