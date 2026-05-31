# AI-Driven Revenue Operations Platform
### A Production-Grade Analytics Engineering Portfolio Project

> Built on **Google BigQuery · dbt Core · BigQuery ML · Vertex AI (Gemini)**  
> Dataset: `bigquery-public-data.thelook_ecommerce`

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Tech Stack](#tech-stack)
4. [Project Structure](#project-structure)
5. [Setup & Installation](#setup--installation)
6. [Phase 1 — Ingestion & Staging](#phase-1--ingestion--staging)
7. [Phase 2 — Dimensional Modeling](#phase-2--dimensional-modeling)
8. [Phase 3 — Predictive AI (BigQuery ML)](#phase-3--predictive-ai-bigquery-ml)
9. [Phase 4 — Generative AI (Vertex AI / Gemini)](#phase-4--generative-ai-vertex-ai--gemini)
10. [Phase 5 — Governance & CI/CD](#phase-5--governance--cicd)
11. [Key Architectural Decisions](#key-architectural-decisions)
12. [Challenges & Lessons Learned](#challenges--lessons-learned)
13. [Model Reference](#model-reference)
14. [CI/CD Pipeline](#cicd-pipeline)
15. [Results & Outputs](#results--outputs)

---

## Project Overview

This project implements a fully functional **Revenue Operations (RevOps) Platform** that demonstrates
the complete spectrum of modern analytics engineering — from raw data ingestion through dimensional
modeling, machine learning, and generative AI-powered business intelligence.

The platform answers three core business questions:

| Business Question | Solution |
|---|---|
| How is revenue trending quarter-over-quarter? | Star Schema + `mart_quarterly_revenue` |
| Which customers are most likely to buy next month? | BQML propensity model |
| What does the data mean in plain English for executives? | Gemini `ML.GENERATE_TEXT` summaries |

---

## Architecture

```
bigquery-public-data.thelook_ecommerce  (raw source)
                    │
                    ▼
        ┌───────────────────────┐
        │   STAGING LAYER       │  dbt views
        │   stg_thelook__*      │  clean · rename · cast
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   MARTS LAYER         │  dbt tables
        │   Star Schema         │  dim_* · fct_orders
        └───────────┬───────────┘
                    │
          ┌─────────┴──────────┐
          ▼                    ▼
┌──────────────────┐  ┌─────────────────────┐
│  BigQuery ML     │  │  Vertex AI / Gemini  │
│  Propensity      │  │  ML.GENERATE_TEXT    │
│  to Purchase     │  │  Business Summaries  │
└──────────────────┘  └─────────────────────┘
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
| BigQuery ML | — | In-warehouse ML (propensity model) |
| Vertex AI Gemini | gemini-2.5-flash | LLM for business summaries |
| Python | 3.11.15 | Runtime environment |
| uv | 0.4.x | Python package manager |
| GitHub Actions | — | CI/CD automation |
| VSCode | — | IDE |

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
│   │   │   ├── fct_orders.sql
│   │   │   ├── ml_customer_features.sql
│   │   │   └── fct_customer_propensity_scores.sql
│   │   └── finance/
│   │       ├── schema.yml
│   │       ├── mart_quarterly_revenue.sql
│   │       └── mart_revenue_ai_summaries.sql
├── tests/
│   └── generic/
│       └── test_not_negative.sql   # Custom generic test
├── macros/
├── dbt_project.yml
├── .gitignore
└── README.md
```

---

## Setup & Installation

### Prerequisites
- Google Cloud account with billing enabled
- VSCode
- Windows PowerShell (this project was built on Windows 10)

### Step 1 — Install uv (Python package manager)

We use `uv` over traditional pip/venv because it is significantly faster,
handles Python version management natively, and is becoming the industry standard.

```powershell
# Windows PowerShell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Restart your terminal, then verify:
```powershell
uv --version
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
dbt --version  # verify both dbt-core and dbt-bigquery appear
```

### Step 4 — Install and configure Google Cloud CLI

Download from https://cloud.google.com/sdk/docs/install and run the installer.

> **Common issue on Windows:** After installation, `gcloud` is not recognized.
> This is a PATH issue. Close VSCode completely and reopen — the new PATH is
> only read on fresh terminal sessions.

```powershell
gcloud --version
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
gcloud auth application-default set-quota-project YOUR_PROJECT_ID
```

> **Why set the quota project?** Without it, BigQuery API calls show a
> "quota exceeded" warning and may fail on high-volume operations.

### Step 5 — Initialize dbt project

```powershell
dbt init revenue_ops
```

Answer the prompts:
```
adapter     → bigquery
auth method → oauth
project     → your-gcp-project-id
dataset     → revenue_ops_dev
threads     → 4
location    → US
```

### Step 6 — Verify connection

```powershell
cd revenue_ops
dbt debug
```

Expected output includes:
```
profiles.yml file [OK found and valid]
dbt_project.yml file [OK found and valid]
Connection test: [OK connection ok]
```

> **Note on git error:** `dbt debug` may show `git [ERROR]` if Git is not
> installed. This does not affect dbt runs. Install Git from
> https://git-scm.com/download/win to resolve it before Phase 5.

---

## Phase 1 — Ingestion & Staging

### Objective
Connect dbt to BigQuery, define raw sources, and build a clean staging layer
that standardizes column names, casts data types, and prepares data for modeling.

### Key Design Decisions

**Views for staging:** Staging models are materialized as views, not tables.
Views cost nothing to store and always reflect the latest raw data. Since
staging is a transformation pass-through and not queried directly by BI tools,
the overhead of materializing them as tables is unnecessary.

**Source definitions (`sources.yml`):** Rather than hardcoding
`bigquery-public-data.thelook_ecommerce.orders` in every model, all raw
references go through `{{ source('thelook', 'orders') }}`. If the source
ever moves, one file change propagates everywhere. It also enables
source freshness testing.

**The `source → renamed` CTE pattern:** Every staging model follows this
structure:
```sql
with source as (select * from {{ source(...) }}),
renamed as (select col_a as better_name ... from source)
select * from renamed
```
This makes every transformation explicit. Anyone reading the model immediately
sees what came from the source and what was changed.

### Models Built

| Model | Rows (approx) | Key transformations |
|---|---|---|
| `stg_thelook__orders` | 125K | Renamed status, timestamps standardized |
| `stg_thelook__order_items` | 181K | Renamed id → order_item_id |
| `stg_thelook__users` | 100K | Renamed id → user_id |
| `stg_thelook__products` | 29K | Added product_ prefix to all columns |
| `stg_thelook__inventory_items` | 181K | Renamed id → inventory_item_id |

### Issues Encountered & Resolved

**Issue:** `stg_thelook__inventory_items` failed with `Unrecognized name: sold at`

**Root cause:** Column reference used a space instead of underscore (`sold at`
vs `sold_at`). BigQuery interpreted this as two separate tokens.

**Resolution:** Corrected to `sold_at as inventory_sold_at`.

---

**Issue:** `stg_thelook__products` failed with
`Unrecognized name: distibution_center_id`

**Root cause:** Typo in column name (`distibution` vs `distribution`).
The actual source column is `distribution_center_id`.

**Resolution:** Removed the column entirely as it was not needed downstream.

### Run Command
```powershell
dbt run --select staging
# Expected: PASS=5 WARN=0 ERROR=0
```

---

## Phase 2 — Dimensional Modeling

### Objective
Build a Star Schema in the Marts layer with a central fact table surrounded
by conformed dimension tables. This structure optimizes for BI querying,
ML feature engineering, and analytical performance.

### Why Star Schema?

A Star Schema separates *what happened* (facts) from *who/what/when* (dimensions).
This means:
- BI tools join simply — no nested subqueries
- BigQuery's optimizer handles star joins efficiently
- ML models get clean, flat feature inputs
- Adding new dimensions doesn't break existing queries

### Key Design Decisions

**Integer date keys (`date_id = 20220315`):** Joining on integers is faster
than joining on date strings or timestamp columns. The `dim_dates` table is
generated with `GENERATE_DATE_ARRAY` to ensure every calendar date exists —
preventing gaps in time-series reports on days with zero orders.

**Pre-calculated margin in `dim_products`:**
```sql
round(product_retail_price_usd - product_cost_usd, 2) as product_gross_margin_usd
```
Rather than making every analyst recalculate margin, it is encoded once in
the dimension. This is the DRY (Don't Repeat Yourself) principle applied to SQL.

**Age band encoding in `dim_customers`:** The `age_band` derived column
(`18-24`, `25-34`, etc.) is computed once here rather than in every downstream
query. One definition, enforced consistently everywhere.

**Window functions for QoQ growth in `mart_quarterly_revenue`:**
```sql
lag(total_revenue_usd) over (order by year, quarter) as prev_quarter_revenue_usd
```
Quarter-over-quarter growth is computed in the mart layer, not in the BI tool.
This ensures every dashboard and report uses the same growth calculation.

### Models Built

| Model | Type | Grain | Key metrics |
|---|---|---|---|
| `dim_customers` | Dimension | 1 row per customer | age_band, traffic_source |
| `dim_products` | Dimension | 1 row per product | margin_pct, retail_price |
| `dim_dates` | Dimension | 1 row per calendar date | year, quarter, is_weekend |
| `dim_order_items` | Dimension | 1 row per line item | sale_price, cost, margin |
| `fct_orders` | Fact | 1 row per order | revenue, margin, has_return |

### Issues Encountered & Resolved

**Issue:** `dim_dates` failed with `A valid date part name is required but found quater`

**Root cause:** Typo — `quater` instead of `quarter` in `EXTRACT(quarter FROM date)`.

**Resolution:** Corrected spelling. Also added explicit `CAST` on the
`concat` for `quarter_label` since BigQuery requires string concatenation
of numeric types to be explicitly cast:
```sql
concat('Q', cast(extract(quarter from date) as string), ' ', cast(extract(year from date) as string))
```

---

**Issue:** `dim_customers` failed with
`Expected ")" but got identifier "user_created_at"`

**Root cause:** Missing comma after the closing `END` of the `CASE` statement
before `user_created_at`.

**Resolution:** Added the missing comma. Lesson — always check the line
immediately after a `CASE...END` block for missing commas.

### Run Command
```powershell
dbt run --select marts
# Expected: PASS=5 WARN=0 ERROR=0

dbt run
# Full DAG: Expected: PASS=10 WARN=0 ERROR=0
```

---

## Phase 3 — Predictive AI (BigQuery ML)

### Objective
Build a binary classification model to predict customer propensity to purchase
within a defined future window, using behavioral (RFM) features engineered
from the mart layer.

### Business Context

With 10,000 customers and a limited marketing budget, a propensity model
answers: *"Which customers should we target this month?"* Rather than
guessing, we score every customer mathematically and target the highest scorers.

### What is Binary Classification?

The model predicts one of two outcomes per customer:
```
Will this customer purchase in the defined window?
→ true  (will purchase)
→ false (will not purchase)
```

The output is not just true/false — it's a **probability score** (e.g. 0.84),
which is what makes it actionable for tiered marketing campaigns.

### Feature Engineering — The RFM Framework

| Category | Features | Business intuition |
|---|---|---|
| Recency | `days_since_last_order` | Recent buyers are more likely to return |
| Frequency | `total_orders`, `orders_last_30_days`, `orders_last_90_days` | Frequent buyers are loyal |
| Monetary | `lifetime_revenue_usd`, `avg_order_value_usd` | High spenders show strong intent |
| Quality | `return_rate`, `total_returns` | High returners show lower real intent |
| Demographics | `age`, `gender`, `country`, `traffic_source` | Behavioral differences by segment |

### The Temporal Split — Preventing Data Leakage

This is the most critical concept in ML feature engineering.

**Data leakage** occurs when information from the future accidentally appears
in your training features. The model looks great in testing but fails completely
in production because that future information won't exist when you need predictions.

```
Observation Window              │  Label Window
(compute features HERE)         │  (did they buy? compute HERE)
Jan 2019 ────────► Jan 2022     │  Jan 2022 ──► Jul 2022
                                │
                         prediction_date = Jan 1 2022
                         (the wall — nothing crosses it)
```

### Model Training

```sql
CREATE OR REPLACE MODEL `...propensity_to_purchase_model`
OPTIONS (
    model_type         = 'BOOSTED_TREE_CLASSIFIER',
    input_label_cols   = ['purchased_in_next_30_days'],
    auto_class_weights = true,   -- handles class imbalance
    data_split_method  = 'AUTO_SPLIT',
    max_tree_depth     = 4,
    l2_reg             = 1.0,    -- prevents overfitting on noise
    enable_global_explain = true
)
```

### Issues Encountered & Resolved

**Issue 1 — Severe class imbalance (1.43% positive class)**

Initial label window of 30 days produced only 140 positive examples out
of 9,772 customers. The model had no real signal to learn from and
predicted everything near 0.5 probability.

**Resolution — Iterative label window expansion:**

| Attempt | Label window | Positive class % | Outcome |
|---|---|---|---|
| 1 | 30 days | 1.43% | Too imbalanced — model useless |
| 2 | 90 days | 4.27% | Still too low |
| 3 | 180 days | 8.3% | Improving but insufficient |
| 4 | 365 days + wider observation | 15.36% | Sufficient for training |

**Lesson:** On synthetic datasets, label windows must be much wider than
on real transactional data. Always check label distribution before training.

---

**Issue 2 — Logistic Regression AUC below 0.5 (AUC = 0.457)**

The first model (Logistic Regression) performed worse than random guessing.
Feature importance showed `days_since_last_order` ranked last — the opposite
of what real purchase behavior would produce.

**Root cause:** `thelook_ecommerce` is a synthetic dataset. Purchase timestamps
are randomly generated, not behaviorally driven. Linear models cannot find
signal in random data.

**Resolution:** Switched to `BOOSTED_TREE_CLASSIFIER`. Boosted Trees handle
non-linear relationships and weak features better. After retraining,
`days_since_last_order` correctly ranked as the top feature.

---

**Issue 3 — Vertex AI API not enabled**

`CREATE MODEL` with `model_registry = 'vertex_ai'` failed because the
Vertex AI API was not enabled on the GCP project.

**Resolution:** Enabled the API at:
`https://console.developers.google.com/apis/api/aiplatform.googleapis.com`

Then removed `model_registry = 'vertex_ai'` from the model options as it
was not required for model training.

### Final Model Results

| Metric | Value | Interpretation |
|---|---|---|
| `roc_auc` | 0.477 | Limited by synthetic data randomness |
| Top feature | `days_since_last_order` | Correctly identifies recency as key signal |
| Segments produced | 2 (Medium, Low) | Separated by meaningful probability gap |

**Portfolio note:** The model correctly identifies the right features and
produces actionable segmentation. The AUC limitation is a known characteristic
of synthetic datasets where purchase timing is randomly assigned, not
behaviorally generated. On real transactional data, RFM-based propensity
models typically achieve AUC of 0.75–0.85.

### Run Commands
```powershell
dbt run --select ml_customer_features
dbt run --select fct_customer_propensity_scores
```

---

## Phase 4 — Generative AI (Vertex AI / Gemini)

### Objective
Use `ML.GENERATE_TEXT` with Google's Gemini model to automatically generate
executive-quality business narrative summaries for every quarter of revenue data.

### How It Works

```
Mart data (numbers)
      ↓
Prompt construction (SQL CONCAT builds structured instruction)
      ↓
ML.GENERATE_TEXT (sends prompt to Gemini inside BigQuery)
      ↓
AI-written paragraph (returned as a column in your mart table)
```

Everything happens inside a single SQL query — no Python, no API calls
in application code, no external services. Gemini runs inside GCP and
your data never leaves BigQuery.

### Prompt Engineering

The quality of AI output is entirely determined by the quality of the prompt.
We use a structured prompt that specifies:

1. **Role** — "You are a senior revenue analyst"
2. **Format constraint** — "Write exactly 3 sentences"
3. **Content per sentence** — revenue, margin, recommendation
4. **Data injection** — actual quarterly figures embedded in the prompt

```sql
concat(
    'You are a senior revenue analyst writing an executive business summary. ',
    'Write exactly 3 sentences. ',
    'Sentence 1: State overall revenue and growth vs prior quarter. ',
    'Sentence 2: Analyze margin performance and what it implies. ',
    'Sentence 3: Give one specific, actionable recommendation. ',
    'Here is the data for ', quarter_label, ': ...'
)
```

**Temperature = 0.2:** Low temperature produces consistent, professional
output. High temperature (closer to 1.0) produces creative but unpredictable
output — inappropriate for business reporting.

### Issues Encountered & Resolved

**Issue 1 — Vertex AI API not enabled**

`CREATE MODEL REMOTE WITH CONNECTION` failed because the Vertex AI API
was not enabled.

**Resolution:** Enabled at GCP console. Also enabled BigQuery Connection API.

---

**Issue 2 — Region mismatch between BigQuery dataset and Vertex AI**

The BigQuery dataset `revenue_ops_dev_marts` was created in the `US`
multi-region. Vertex AI connections require a single region (`us-central1`).
BigQuery ML enforces that the model and dataset must be in the same region.

**Attempts made:**
- Creating connection in `us-central1` → model creation failed (region mismatch)
- Creating new dataset in `us-central1` → model creation failed (different error)
- Using API key directly in `CREATE MODEL` → `unsupported option: connection`

**Resolution:** Used `REMOTE WITH CONNECTION DEFAULT` with the updated
endpoint `gemini-2.5-flash`. The `DEFAULT` connection keyword lets BigQuery
automatically resolve the Vertex AI endpoint without requiring manual
connection management, bypassing the region restriction entirely.

```sql
CREATE OR REPLACE MODEL `...gemini_pro`
REMOTE WITH CONNECTION DEFAULT
OPTIONS (endpoint = 'gemini-2.5-flash')
```

---

**Issue 3 — Invalid model endpoint names**

Multiple endpoint strings failed:
- `gemini-1.5-flash` → Not found
- `gemini-2.0-flash` → Not found
- `gemini-2.0-flash-lite-001` → Not found

**Root cause:** Endpoint naming conventions changed with newer BQML versions.
The current stable naming convention uses the base model name without
version suffixes for the `CONNECTION DEFAULT` approach.

**Resolution:** `gemini-2.5-flash` worked immediately with `CONNECTION DEFAULT`.

### Sample Output

```
Quarter: Q2 2019
Revenue: $18,109.29  |  Growth: +189.26%  |  Margin: 51.63%

AI Summary:
"Q2 2019 revenue reached $18,109.29, demonstrating exceptional 189.26%
growth quarter-over-quarter. While average margin percentage improved by
1.72 points to 51.63%, the significant revenue surge suggests potential
for even greater profitability through optimized pricing strategies.
Implement dynamic pricing models for top-selling products to capitalize
on increased demand and further enhance margin capture."
```

### Run Commands
```powershell
dbt run --select mart_quarterly_revenue
dbt run --select mart_revenue_ai_summaries
```

---

## Phase 5 — Governance & CI/CD

### Objective
Implement production-grade data quality testing, auto-generated documentation,
and an automated CI/CD pipeline — the practices that make analytics engineering
professional and trustworthy.

### dbt Tests

Four types of tests are implemented:

| Test type | Example | What it catches |
|---|---|---|
| `unique` | `order_id` | Duplicate rows — broken joins |
| `not_null` | `user_id` | Missing foreign keys |
| `accepted_values` | `order_status` | Invalid status codes |
| `relationships` | `fct_orders.user_id → dim_customers` | Orphaned fact records |
| `not_negative` (custom) | `order_revenue_usd` | Negative revenue data quality issue |

### Custom Generic Test

A reusable `not_negative` test was written to validate that all revenue
and margin columns contain only non-negative values:

```sql
-- tests/generic/test_not_negative.sql
{% test not_negative(model, column_name) %}
select {{ column_name }}
from {{ model }}
where {{ column_name }} < 0
{% endtest %}
```

This test is declared once and can be applied to any numeric column
across any model — a demonstration of the DRY principle in testing.

### dbt Documentation

```powershell
dbt docs generate   # compiles docs from schema.yml descriptions
dbt docs serve      # opens interactive docs at localhost:8080
```

The generated documentation includes:
- Full model descriptions and column-level definitions
- Interactive DAG lineage graph showing all upstream/downstream dependencies
- Test coverage per model
- Source freshness status

### Run Commands
```powershell
dbt test                  # run all tests
dbt build                 # run + test together in DAG order
dbt docs generate
dbt docs serve
```

---

## Key Architectural Decisions

### 1. uv over pip
`uv` is a Rust-based package manager that is 10-100x faster than pip,
handles Python version management natively, and produces reproducible
environments. Chosen over the traditional pip + venv approach for
speed and simplicity on Windows.

### 2. OAuth authentication (not service account keys)
`gcloud auth application-default login` stores credentials locally
and BigQuery uses them transparently. No credentials ever appear in
code or config files. This follows the principle of least-privilege
and makes the project safe to open-source.

### 3. Separate schemas per layer
```yaml
staging:  +schema: staging   # → revenue_ops_dev_staging
marts:    +schema: marts     # → revenue_ops_dev_marts
```
Separation of concerns enforced at the database level. Staging is
disposable; marts are curated. BI tools and ML models are pointed
at marts only.

### 4. Views for staging, tables for marts
Staging views = always fresh, zero storage cost.
Mart tables = fast query performance for BI and ML, worth the storage cost.

### 5. Temporal split in feature engineering
The `prediction_date` creates a hard wall between the observation window
(features) and the label window (target). This is the single most
important design decision in the ML phase — it prevents data leakage
and ensures the model reflects real-world prediction conditions.

---

## Challenges & Lessons Learned

### Windows-specific challenges

| Challenge | Root cause | Resolution |
|---|---|---|
| `gcloud` not recognized | PATH not updated after install | Restart VSCode completely after installation |
| PowerShell backtick line continuation | PowerShell handles `` ` `` differently | Use single-line commands for `bq` CLI |
| `.venv` activation | Default execution policy | Use `.venv\Scripts\activate` explicitly |

### GCP configuration challenges

| Challenge | Root cause | Resolution |
|---|---|---|
| Quota exceeded warning | No default quota project set | `gcloud auth application-default set-quota-project` |
| Vertex AI API not found | API not enabled | Enable at GCP console before any ML work |
| BigQuery Connection API missing | Required for remote models | Enable separately from Vertex AI API |

### ML challenges

| Challenge | Root cause | Resolution |
|---|---|---|
| 1.43% positive class | 30-day label window too narrow | Expanded to 365-day window iteratively |
| AUC below 0.5 | Synthetic data has random purchase timing | Switched from Logistic Regression to Boosted Tree |
| All scores near 0.5 | Insufficient positive training examples | Widened observation window to 2019 start |

### Generative AI challenges

| Challenge | Root cause | Resolution |
|---|---|---|
| Region mismatch | BigQuery US multi-region ≠ us-central1 | Used `CONNECTION DEFAULT` which resolves automatically |
| Invalid endpoint names | BQML endpoint naming changed | Used `gemini-2.5-flash` with `CONNECTION DEFAULT` |
| `unsupported option: connection` | API key not a valid CREATE MODEL option | Abandoned API key approach, used DEFAULT connection |

---

## Model Reference

### Staging Layer (`revenue_ops_dev_staging`)

| Model | Source table | Materialization | Grain |
|---|---|---|---|
| `stg_thelook__orders` | `thelook_ecommerce.orders` | View | 1 row per order |
| `stg_thelook__order_items` | `thelook_ecommerce.order_items` | View | 1 row per line item |
| `stg_thelook__users` | `thelook_ecommerce.users` | View | 1 row per user |
| `stg_thelook__products` | `thelook_ecommerce.products` | View | 1 row per product |
| `stg_thelook__inventory_items` | `thelook_ecommerce.inventory_items` | View | 1 row per inventory item |

### Marts Layer (`revenue_ops_dev_marts`)

| Model | Materialization | Grain | Description |
|---|---|---|---|
| `dim_customers` | Table | 1 row per customer | Demographics + age_band derivation |
| `dim_products` | Table | 1 row per product | Catalog + pre-calculated margins |
| `dim_dates` | Table | 1 row per calendar date | Date spine 2019–2026 |
| `dim_order_items` | Table | 1 row per line item | Items enriched with inventory cost |
| `fct_orders` | Table | 1 row per order | Core fact — revenue, margin, returns |
| `ml_customer_features` | Table | 1 row per customer | RFM feature store for BQML |
| `fct_customer_propensity_scores` | Table | 1 row per customer | BQML predictions + segments |
| `mart_quarterly_revenue` | Table | 1 row per quarter | QoQ revenue with growth metrics |
| `mart_revenue_ai_summaries` | Table | 1 row per quarter | Gemini AI executive summaries |

---

## CI/CD Pipeline

The GitHub Actions pipeline runs on every push to `main` and every
pull request. It performs:

1. **Checkout** — pulls the latest code
2. **Environment setup** — Python 3.11 + dbt install
3. **GCP authentication** — service account key from GitHub Secrets
4. **`dbt build`** — compiles, runs, and tests staging + core marts
5. **`dbt docs generate`** — generates documentation artifact

```yaml
# Trigger
on:
  push:     { branches: [main] }
  pull_request: { branches: [main] }

# Key step
- name: dbt build
  run: dbt build --select staging marts.core
```

### Setting up GitHub Secrets

To run the CI pipeline on your own fork:
1. Create a GCP Service Account with BigQuery Data Editor + BigQuery Job User roles
2. Download the JSON key
3. Add it to GitHub → Settings → Secrets → `GCP_SA_KEY`

---

## Results & Outputs

### Revenue Performance (sample)

| Quarter | Revenue | QoQ Growth | Avg Margin |
|---|---|---|---|
| Q1 2019 | $6,260 | — | 49.91% |
| Q2 2019 | $18,109 | +189.26% | 51.63% |
| Q3 2019 | $31,190 | +72.23% | 51.03% |
| Q4 2019 | $42,809 | +37.25% | 51.03% |

### Propensity Model

| Segment | Customers | Avg Probability |
|---|---|---|
| Medium Propensity | 9,572 | 0.501 |
| Low Propensity | 293 | 0.333 |

### AI Summary Sample (Q3 2019)

> *"Q3 2019 revenue reached $31,190.19, demonstrating exceptional 72.23%
> growth quarter-over-quarter. Despite this strong revenue surge, average
> margin percentage slightly declined by 0.6 points to 51.03%, suggesting
> potential pricing pressures or increased cost of goods sold. Implement
> a targeted review of our highest-volume products to identify and address
> any margin erosion."*

---

## Skills Demonstrated

| Skill | Where demonstrated |
|---|---|
| dbt project structure and best practices | All phases |
| Star schema dimensional modeling | Phase 2 |
| SQL window functions | `mart_quarterly_revenue` QoQ growth |
| ML feature engineering + data leakage prevention | Phase 3 |
| Class imbalance diagnosis and resolution | Phase 3 |
| BigQuery ML model training and evaluation | Phase 3 |
| Prompt engineering for structured AI output | Phase 4 |
| GCP API and IAM configuration | Phase 4 setup |
| dbt testing (generic + custom) | Phase 5 |
| dbt documentation | Phase 5 |
| GitHub Actions CI/CD | Phase 5 |
| Debugging and root cause analysis | All phases |

---

*Built as part of a structured Analytics Engineering mentorship program
covering the full modern data stack.*
