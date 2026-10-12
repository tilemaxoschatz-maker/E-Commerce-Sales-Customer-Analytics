# Olist E-Commerce: SQL Analytics & KPI Dashboard

End-to-end data analytics project on the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — from raw, multi-table data in PostgreSQL through cleaning, 40 business questions, a consolidated KPI layer, and a Tableau dashboard.

## Overview

Olist is a Brazilian e-commerce marketplace connecting small businesses to major online sales channels. This project builds a full analytics pipeline on top of 9 raw Olist tables (customers, orders, order items, payments, reviews, products, sellers, geolocation, and category translations), answering business questions across revenue, delivery performance, product/category performance, and customer satisfaction — then surfaces the results as a live Tableau dashboard.

**Stack:** PostgreSQL (cleaning, modeling, analysis) → Tableau (visualization)

## Project Structure

```
olist-ecommerce-kpi-dashboard/
├── sql/
│   ├── E-Commerce Sales & Customer Analytics.sql   # Full pipeline: raw tables → cleaning → views → 40 business questions
│   ├── olist_kpi_views.sql                          # Consolidated KPI view layer (4 views) built from the BQs
│   └── olist_kpi_comments.sql                       # Inline COMMENT ON documentation for the KPI views
├── docs/
│   └── kpi_data_dictionary.md                        # Column-level data dictionary for the 4 KPI views
├── dashboard/
│   ├── olist_kpi_dashboard.twb                        # Tableau workbook
│   └── screenshots/
│       └── dashboard_overview.png                      # Dashboard screenshot (Tableau Free Edition can't publish live)
└── README.md
```

## Data Pipeline

**1. Raw ingestion** — 9 source tables loaded with primary/foreign key constraints, then validated: row counts, duplicate checks, referential integrity, NULL audits.

**2. Cleaning** — working copies of every raw table (`olist_*_clean`), fixing nulls, inconsistent types, and chronology issues (e.g. delivery dates before purchase dates), with a `delivery_performance` flag engineered on the orders table (Late / On Time / Early).

**3. Analytical views** — order-grain and item-grain views (`vw_order_analysis`, `vw_product_analysis`) joining cleaned tables while explicitly controlling table grain before aggregation, to avoid fan-out/double-counting from the one-to-many item/payment/review relationships.

**4. Business questions** — 40 numbered SQL queries (`BQ01`–`BQ40`) spanning:
   - Revenue, AOV, growth
   - Delivery performance (on-time rate, delay distribution, by state)
   - Product & category performance
   - Seller performance and risk (high revenue / low satisfaction)
   - Customer satisfaction and repeat-purchase behavior

**5. KPI view layer** (`olist_kpi_views.sql`) — consolidates the 40 BQs into 4 dashboard-ready views so Tableau queries pre-aggregated data instead of re-deriving logic as calculated fields:

| View | Grain | Consolidates |
|---|---|---|
| `vw_kpi_summary` | 1 row | Headline totals: orders, revenue, AOV, delivery %, repeat-customer rate, review scores |
| `vw_kpi_by_state` | 1 row / state | Revenue, volume, AOV, % of total revenue, delivery performance by customer state |
| `vw_kpi_by_category` | 1 row / category | Revenue, volume, AOV, review score by product category |
| `vw_kpi_by_seller` | 1 row / seller | Revenue, AOV, review score, delivery performance, and a `low_review_flag` risk indicator |

Each view and column is documented inline via `COMMENT ON` (`olist_kpi_comments.sql`) and in the full data dictionary (`docs/kpi_data_dictionary.md`).

## Dashboard

Built in Tableau on top of the 4 KPI views:

- **KPI summary tiles** — total orders, revenue, AOV, delivery rate, repeat-customer rate, review scores
- **Top 15 Categories by Revenue** — bar chart, colored by average review score
- **Revenue by State** — bar chart, colored by late-delivery rate
- **Revenue vs. Review Score (seller risk)** — scatter plot of all sellers with ≥20 delivered orders, flagging sellers with high revenue but low satisfaction (`avg_review_score < 3`)

![Dashboard overview](dashboard/screenshots/dashboard_overview.png)

## Key Findings

- **São Paulo (SP) dominates revenue** — ~38% of total revenue and the largest order volume by a wide margin, consistent with its role as Brazil's largest commercial state.
- **97.0%** of orders are successfully delivered, with an average delivery time of **12.6 days** and an **8.1%** late-delivery rate.
- Only **3.0%** of customers are repeat buyers (avg. 1.03 orders/customer) — a clear opportunity area for retention.
- Overall review sentiment is solid (avg. **4.09 / 5**), though **14.7%** of reviews are low (≤2), concentrated among a small number of sellers rather than spread evenly.
- A small set of sellers combine meaningful order volume with review scores below 3.0 — flagged directly in the dashboard as retention/quality risks.

## Design Notes

- **Grain control**: `vw_kpi_by_category` and `vw_kpi_by_seller` are built via intermediate CTEs at the order/category and order/seller grain before joining back to item-level data — avoiding the double-counting that a naive single `GROUP BY` over item rows would cause when an order contains multiple line items.
- **Seller risk threshold**: the ≥20-delivered-orders filter (carried over from BQ40) is applied at query/dashboard-filter time, not hardcoded into the view, so the underlying data stays complete and the threshold stays adjustable.
- **Currency**: all revenue figures are in BRL (Brazilian Real).

## Author

Tilemachos — Junior Data Analyst project, built end-to-end in PostgreSQL + Tableau.
