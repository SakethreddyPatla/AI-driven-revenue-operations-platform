with date_spine as (
    select
        date
    from unnest(
            generate_date_array('2019-01-01', '2026-12-31')
    ) as date
),

final as (
    select 
        cast(format_date('%Y%m%d', date) as int64) as date_id,
        date as full_date,
        extract(year from date) as year,
        extract(quarter from date) as quarter,
        extract(month from date) as month_number,
        format_date('%B', date) as month_name,
        format_date('%b', date) as month_short,
        extract(week from date) as week_of_year,
        extract(dayofweek from date) as day_of_week,
        format_date('%A', date) as day_name,
        case    
            when extract(dayofweek from date) in (1, 7) then true else false
        end as is_weekend,
        concat(
            'Q', extract(quarter from date), ' ', extract(year from date)
        ) as quarter_label
    from date_spine
)

select * from final