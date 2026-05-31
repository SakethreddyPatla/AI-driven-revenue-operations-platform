{{
    config(
        materialized = 'table'
    )
}}

with quarterly_data as (
    select * from {{ ref('mart_quaterly_revenue') }}
),

-- build a detailed prompt for each quarter
prompts as (
    select
        quarter_label,
        year,
        quarter,
        total_revenue_usd,
        total_margin_usd,
        avg_margin_pct,
        total_orders,
        unique_customers,
        return_rate_pct,
        revenue_growth_pct,
        margin_change_pp,

        -- construct the prompt as a string
        concat(
            'You are a senior revenue analyst writing an executive business summary. ',
            'Be concise, specific, and data-driven. Write exactly 3 sentences. ',
            'Sentence 1: State overall revenue and growth vs prior quarter. ',
            'Sentence 2: Analyze margin performance and what it implies. ',
            'Sentence 3: Give one specific, actionable recommendation. ',
            'Here is the data for ', quarter_label, ': ',
            'Total Revenue: $', cast(total_revenue_usd as string), '. ',
            'Revenue Growth vs Prior Quarter: ',
                coalesce(cast(revenue_growth_pct as string), 'N/A (first quarter)'), '%. ',
            'Total Gross Margin: $', cast(total_margin_usd as string), '. ',
            'Average Margin %: ', cast(avg_margin_pct as string), '%. ',
            'Margin Change vs Prior Quarter: ',
                coalesce(cast(margin_change_pp as string), 'N/A'), ' percentage points. ',
            'Total Orders: ', cast(total_orders as string), '. ',
            'Unique Customers: ', cast(unique_customers as string), '. ',
            'Return Rate: ', cast(return_rate_pct as string), '%.'
        )                                               as prompt

    from quarterly_data
),

-- send each prompt to gemini
ai_summaries as (
    select *
    from ml.generate_text(
        model `vernal-dispatch-496019-v9.revenue_ops_dev_marts.gemini_pro`,
        table prompts,
        struct(
            0.2    as temperature,
            300    as max_output_tokens,
            true   as flatten_json_output
        )
    )
)

select
    quarter_label,
    year,
    quarter,
    total_revenue_usd,
    total_margin_usd,
    avg_margin_pct,
    revenue_growth_pct,
    margin_change_pp,
    total_orders,
    return_rate_pct,
    ml_generate_text_llm_result        as ai_business_summary,
    ml_generate_text_status            as ai_status,
    current_timestamp()                as generated_at

from ai_summaries
order by year, quarter