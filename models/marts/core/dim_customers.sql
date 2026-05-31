with customers as (
    select * from {{ ref('stg_thelook__users') }}
),

final as (
    select
        user_id,
        first_name,
        last_name,
        concat(first_name, ' ', last_name) as full_name,
        email,
        age,
        gender,
        postal_code,
        city,
        state,
        country,
        traffic_source,
        case 
            when age < 18 then 'Under 18' 
            when age < 25 then '18-24'
            when age < 35 then '25-34'
            when age < 45 then '35-44'
            when age < 55 then '45-54'
            when age >= 55 then '55+'
            else 'Unknown'
        end as age_band,
        user_created_at
    from customers
)

select * from final