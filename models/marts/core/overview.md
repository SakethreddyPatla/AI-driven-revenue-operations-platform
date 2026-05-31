# Revenue Operations Platform

## Project Overview
This dbt project transforms raw eCommerce data from `bigquery-public-data.thelook_ecommerce`
into a production-grade analytics layer powering revenue reporting, customer segmentation,
and AI-driven business intelligence.

## Layer Architecture

| Layer | Location | Materialization | Purpose |
|---|---|---|---|
| Staging | `revenue_ops_dev_staging` | Views | Clean and rename raw sources |
| Marts Core | `revenue_ops_dev_marts` | Tables | Star schema for analytics and ML |
| Marts Finance | `revenue_ops_dev_marts` | Tables | Revenue reporting and AI summaries |

## Key Models

- **`fct_orders`** — Central fact table. One row per order with revenue and margin metrics
- **`ml_customer_features`** — RFM feature store for propensity model. Temporal split prevents leakage
- **`fct_customer_propensity_scores`** — BQML predictions with marketing segments
- **`mart_revenue_ai_summaries`** — Gemini-generated executive summaries per quarter

## Data Lineage
Raw Sources → Staging (views) → Dimension Tables → Fact Tables → ML Features → AI Summaries