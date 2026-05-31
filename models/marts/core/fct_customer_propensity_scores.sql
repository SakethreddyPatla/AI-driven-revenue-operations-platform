{{
    config(
        materialized = 'table'
    )
}}

with predictions as (
    select *
    from ml.predict(
        model `vernal-dispatch-496019-v9.revenue_ops_dev_marts.propensity_to_purchase_model`,
        (
            select * 
            from {{ ref('ml_customer_features') }}
        )
    )
),
customers as (
    select * from {{ ref('dim_customers') }}
),
final as (
    select
        p.user_id,
        c.full_name,
        c.email,
        c.country,
        c.age_band,
        c.traffic_source,

        -- prediction output
        p.predicted_purchased_in_next_30_days as will_purchase,

        -- probability scores (the real business value)
        round(
            (
                select prob.prob
                from unnest(p.predicted_purchased_in_next_30_days_probs) as prob
                where prob.label = true
            ), 4
        ) as purchase_probability,

        -- segmentation for marketing
        case
            when (
                select prob.prob
                from unnest(p.predicted_purchased_in_next_30_days_probs) as prob
                where prob.label = true
            ) >= 0.70 then 'High Propensity'
            when (
                select prob.prob
                from unnest(p.predicted_purchased_in_next_30_days_probs) as prob
                where prob.label = true
            ) >= 0.40 then 'Medium Propensity'
            else 'Low Propensity'
        end as propensity_segment,

        current_timestamp() as scored_at

    from predictions p
    left join customers c on p.user_id = c.user_id
)

select * from final
order by purchase_probability desc