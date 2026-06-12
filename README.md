# Production-Grade Revenue Operations Platform
### A Production-Grade Analytics Engineering Portfolio Project

> Built on **Google BigQuery · dbt Core · GitHub Actions** > Dataset: `bigquery-public-data.thelook_ecommerce`

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Tech Stack](#tech-stack)
4. [Project Structure](#project-structure)
5. [Setup & Installation](#setup--installation)
6. [Phase 1 — Ingestion & Staging](#phase-1--ingestion--staging)
7. [Phase 2 — Dimensional Modeling](#phase-2--dimensional-modeling)
8. [Phase 3 — Governance & CI/CD](#phase-3--governance--cicd)
9. [Key Architectural Decisions](#key-architectural-decisions)
10. [Challenges & Lessons Learned](#challenges--lessons-learned)
11. [Model Reference](#model-reference)
12. [CI/CD Pipeline](#cicd-pipeline)
13. [Results & Outputs](#results--outputs)

---

## Project Overview

This project implements a fully functional **Revenue Operations (RevOps) Platform** that demonstrates the complete spectrum of core modern analytics engineering — from raw data ingestion through dimensional modeling and automated warehouse testing infrastructure.

The platform systematically resolves core operational reporting metrics:

| Business Question | Solution |
|---|---|
| How is revenue trending quarter-over-quarter? | Star Schema + `mart_quarterly_revenue` |

---

## Architecture

```
bigquery-public-data.thelook_ecommerce  (raw source)
                    │
                    ▼
        ┌───────────────────────┐
        │   STAGING LAYER       │  dbt views
        │   stg_thelook__* │  clean · rename · cast
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   MARTS LAYER         │  dbt tables
        │   Star Schema         │  dim_* · fct_orders
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   CI/CD PIPELINE      │
        │   GitHub Actions      │
        │   dbt test on PR      │
        └───────────────────────┘
```

### Star Schema Design

```
                    ┌─────────────┐
                    │  dim_dates  │
                    │  date_id PK │
                    └──────┬──────┘
                           │ date_id
          ┌────────────────┼────────────────┐
          │                │                │
   user_id│         ┌──────▼──────┐         │product_id
┌─────────┴──────┐  │  fct_orders │  ┌──────┴──────────┐
│ dim_customers  │  │  order_id PK│  │  dim_products   │
│  user_id PK    ◄──┤  revenue    ├──►  product_id PK  │
│  demographics  │  │  margin     │  │  brand/category │
└────────────────┘  │  returns    │  └─────────────────┘
                    └──────┬──────┘
                           │ order_item_id
                    ┌──────▼──────────┐
                    │ dim_order_items  │
                    │ order_item_id PK │
                    │ status · margin  │
                    └─────────────────┘
```

---

## Tech Stack

| Tool | Version | Purpose |
|---|---|---|
| Google BigQuery | — | Cloud data warehouse |
| dbt Core | 1.11.9 | Data transformation and modeling |
| dbt-bigquery | 1.11.1 | BigQuery adapter for dbt |
| Python | 3.11.15 | Runtime environment |
| uv | 0.4.x | Python package manager |
| GitHub Actions | — | CI/CD automation |

---

## Project Structure

```
revenue_ops/
├── .github/
│   └── workflows/
│       └── dbt_ci.yml              # GitHub Actions CI pipeline
├── models/
│   ├── staging/
│   │   └── thelook/
│   │       ├── sources.yml         # Source definitions & freshness tests
│   │       ├── schema.yml          # Staging model tests & docs
│   │       ├── stg_thelook__orders.sql
│   │       ├── stg_thelook__order_items.sql
│   │       ├── stg_thelook__users.sql
│   │       ├── stg_thelook__products.sql
│   │       └── stg_thelook__inventory_items.sql
│   ├── marts/
│   │   ├── core/
│   │   │   ├── schema.yml          # Mart model tests & docs
│   │   │   ├── dim_customers.sql
│   │   │   ├── dim_products.sql
│   │   │   ├── dim_dates.sql
│   │   │   ├── dim_order_items.sql
│   │   │   └── fct_orders.sql
│   │   └── finance/
│   │       ├── schema.yml
│   │       └── mart_quarterly_revenue.sql
├── tests/
│   └── generic/
│       └── test_not_negative.sql   # Custom generic test
├── macros/
├── dbt_project.yml
└── README.md
```

---

## Setup & Installation

### Step 1 — Install uv (Python package manager)

```powershell
powershell -ExecutionPolicy ByPass -c "irm [https://astral.sh/uv/install.ps1](https://astral.sh/uv/install.ps1) | iex"
```

### Step 2 — Create the project environment

```powershell
mkdir revenue_ops_platform
cd revenue_ops_platform
uv python install 3.11
uv venv .venv --python 3.11
.venv\Scripts\activate
```

### Step 3 — Install dbt

```powershell
uv pip install dbt-core dbt-bigquery
```

### Step 4 — Install and configure Google Cloud CLI

```powershell
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
gcloud auth application-default set-quota-project YOUR_PROJECT_ID
```

---

## Phase 1 — Ingestion & Staging

### Key Design Decisions

* **Views for staging:** Staging models are materialized as views, not tables. Views cost nothing to store and always reflect the latest raw data.
* **Source definitions (`sources.yml`):** Rather than hardcoding references, all queries run through `{{ source() }}` to allow global modifications and implement automated freshness metadata assertions.
* **The `source → renamed` CTE pattern:** Every model explicitly maps source rows into typed, renamed transformation layers within isolated Common Table Expressions.

### Models Built

| Model | Rows (approx) | Key transformations |
|---|---|---|
| `stg_thelook__orders` | 125K | Renamed status, timestamps standardized |
| `stg_thelook__order_items` | 181K | Renamed id → order_item_id |
| `stg_thelook__users` | 100K | Renamed id → user_id |
| `stg_thelook__products` | 29K | Added product_ prefix to all columns |
| `stg_thelook__inventory_items` | 181K | Renamed id → inventory_item_id |

---

## Phase 2 — Dimensional Modeling

### Key Design Decisions

* **Integer date keys (`date_id = 20220315`):** Joining on integer representations preserves partitioning filters and speeds up execution paths within column-store architectures like BigQuery compared to timestamp strings.
* **Pre-calculated margin in `dim_products`:** Financial metric calculations are computed strictly upstream within the dimensional logic block to maintain absolute DRY compliance across downstream query dependencies.
* **Window functions for QoQ growth in `mart_quarterly_revenue`:** Core analytical tracking computations are hardcoded using native SQL analytical `LAG()` expressions to lower visualization runtime overhead.

### Models Built

| Model | Type | Grain | Key metrics |
|---|---|---|---|
| `dim_customers` | Dimension | 1 row per customer | age_band, traffic_source |
| `dim_products` | Dimension | 1 row per product | margin_pct, retail_price |
| `dim_dates` | Dimension | 1 row per calendar date | year, quarter, is_weekend |
| `dim_order_items` | Dimension | 1 row per line item | sale_price, cost, margin |
| `fct_orders` | Fact | 1 row per order | revenue, margin, has_return |

---

## Phase 3 — Governance & CI/CD

### dbt Tests

| Test type | Example | What it catches |
|---|---|---|
| `unique` | `order_id` | Duplicate rows — broken joins |
| `not_null` | `user_id` | Missing foreign keys |
| `accepted_values` | `order_status` | Invalid status codes |
| `relationships` | `fct_orders.user_id → dim_customers` | Orphaned fact records |
| `not_negative` (custom) | `order_revenue_usd` | Negative revenue data quality issue |

### Custom Generic Test

```sql
-- tests/generic/test_not_negative.sql
{% test not_negative(model, column_name) %}
select {{ column_name }}
from {{ model }}
where {{ column_name }} < 0
{% endtest %}
```

---

## Key Architectural Decisions

1. **uv over pip:** `uv` optimizes isolated runtime replication speeds while completely mitigating package dependency resolution lock issues.
2. **OAuth Authentication Boundaries:** Enforcing local identity access integration using Application Default Credentials eliminates systemic security vulnerabilities tied to static cloud keys.
3. **Distinct Target Environments:** Enforced database schema partitioning boundaries (`revenue_ops_dev_staging` vs `revenue_ops_dev_marts`) to separate downstream curated tables from intermediate views.

---

## Challenges & Lessons Learned

### 1. GCP Cloud Storage and Project Quota Limits
* **Context:** Executing commands inside the engine assigned API call limits against shared default limits instead of tracking active runtime identities directly.
* **Resolution:** Re-routed authorization configurations to reference the explicit development tracking space:
  ```powershell
  gcloud auth application-default set-quota-project YOUR_PROJECT_ID
  ```

### 2. BigQuery Type Evaluation Boundaries
* **Context:** BigQuery strictly rejects implicit type promotion formatting when trying to merge raw text literals directly with dynamic numerical outputs during the Date Spine processing steps.
* **Resolution:** Rewrote data assembly strings to introduce explicit `CAST` expressions around the numerical variables:
  ```sql
  concat('Q', cast(extract(quarter from date) as string), ' ', cast(extract(year from date) as string))
  ```

---

## Model Reference

### Staging Layer (`revenue_ops_dev_staging`)

| Model | Materialization | Grain | Description |
|---|---|---|---|
| `stg_thelook__orders` | View | 1 row per order | Sanitized transaction entries |
| `stg_thelook__order_items` | View | 1 row per line item | Individual item line items |
| `stg_thelook__users` | View | 1 row per user | Normalised user parameters |
| `stg_thelook__products` | View | 1 row per product | Master product descriptions |

### Marts Layer (`revenue_ops_dev_marts`)

| Model | Materialization | Grain | Description |
|---|---|---|---|
| `dim_customers` | Table | 1 row per customer | Demographics + age_band derivation |
| `dim_products` | Table | 1 row per product | Catalog + pre-calculated margins |
| `dim_dates` | Table | 1 row per calendar date | Date spine 2019–2026 |
| `fct_orders` | Table | 1 row per order | Core fact — revenue, margin, returns |
| `mart_quarterly_revenue` | Table | 1 row per quarter | QoQ revenue with growth metrics |

---

## CI/CD Pipeline

```yaml
on:
  push:     { branches: [main] }
  pull_request: { branches: [main] }

jobs:
  dbt_build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Assets
        run: dbt build --select staging marts.core
```

---

## Results & Outputs

### Revenue Performance Output

| Quarter | Revenue | QoQ Growth | Avg Margin |
|---|---|---|---|
| Q1 2019 | $6,260 | — | 49.91% |
| Q2 2019 | $18,109 | +189.26% | 51.63% |
| Q3 2019 | $31,190 | +72.23% | 51.03% |
| Q4 2019 | $42,809 | +37.25% | 51.03% |

---

## Skills Demonstrated

* dbt warehouse project architecture compilation and orchestration
* Multi-layer Star Schema modeling design paradigms
* SQL analytic partition implementations (`LAG`)
* Cloud API identity scope management and resource optimization
* Jinja-driven polymorphic structural schema testing expansion frameworks
* GitHub Actions continuous execution and testing automations
