# 🛒 E-Commerce Business Intelligence — SQL Case Study

**Author:** Naga Jyothi Chavali  
**Tools:** PostgreSQL · SQL (CTEs, Window Functions, Aggregations, Subqueries)  
**Dataset:** Simulated UK Online Retail (modelled on UCI Online Retail II structure)  
**Objective:** Answer 18 real business questions across revenue, customer behaviour, product performance, and anomaly detection using SQL alone.

---

## 📌 Project Overview

An end-to-end SQL analysis of a UK online retail business, exploring revenue trends, customer behaviour, product performance, and operational anomalies. The goal is to answer questions a real analytics team would face — using only SQL, from a cold dataset, with clear business interpretation for each result.

---

## 🗂️ Database Schema

Four tables with realistic relationships:

```
customers       — customer_id, country, signup_date, customer_segment
products        — product_id, description, category, unit_price
orders          — order_id, customer_id, order_date, status
order_items     — order_item_id, order_id, product_id, quantity, unit_price, discount_pct
```

Order status values: `Completed`, `Cancelled`, `Returned`  
Customer segments: `New`, `Returning`, `VIP`

**Setup:** Run `schema_and_data.sql` in any PostgreSQL environment (or adapt for MySQL/SQLite).

---

## 📊 Queries — Business Questions Answered

### Section 1: Revenue Analysis

| # | Business Question | Key Technique |
|---|---|---|
| Q1 | How is revenue trending month-on-month? | GROUP BY with TO_CHAR date formatting |
| Q2 | Which product categories drive the most revenue? | Multi-table JOIN + aggregation |
| Q3 | Are we growing vs last year (YoY)? | Self-join CTE + NULLIF for safe division |
| Q4 | Do VIP customers justify their acquisition cost? | Segment-level aggregation + revenue per customer |

### Section 2: Customer Behaviour

| # | Business Question | Key Technique |
|---|---|---|
| Q5 | Who are our highest lifetime-value customers? | CLV calculation with date range |
| Q6 | Which markets spend most per order (AOV)? | Country-level AOV |
| Q7 | How many customers are one-time vs repeat buyers? | Frequency distribution + window % |
| Q8 | Of customers who joined each quarter, how many returned? | Cohort retention with DATE_TRUNC |

### Section 3: Product Performance

| # | Business Question | Key Technique |
|---|---|---|
| Q9 | Which products should we prioritise for stock and marketing? | Revenue + discount analysis per SKU |
| Q10 | Which products are frequently bought together? | Self-join on order_items for affinity |
| Q11 | Which products are underperforming (removal candidates)? | LEFT JOIN + HAVING for low-sales filter |

### Section 4: Operational & Anomaly Analysis

| # | Business Question | Key Technique |
|---|---|---|
| Q12 | Are cancellations and returns increasing? | CASE WHEN pivot for status counts |
| Q13 | How much revenue are we losing to bad orders? | Status-filtered revenue aggregation |
| Q14 | Which orders are statistical outliers (possible fraud)? | Z-score using AVG + STDDEV in CTE |
| Q15 | Are discounts generating volume or eroding margin? | Discount banding with CASE + margin calc |

### Section 5: Window Functions

| # | Business Question | Key Technique |
|---|---|---|
| Q16 | Track cumulative revenue vs targets | SUM() OVER with ORDER BY (running total) |
| Q17 | Rank customers within each segment by spend | DENSE_RANK() OVER PARTITION BY |
| Q18 | Which months saw the biggest revenue swings? | LAG() for MoM comparison |

---

## 💡 Sample Query — Cohort Retention (Q8)

```sql
WITH customer_cohorts AS (
    SELECT
        c.customer_id,
        DATE_TRUNC('quarter', c.signup_date)::DATE  AS cohort_quarter,
        DATE_TRUNC('quarter', o.order_date)::DATE   AS order_quarter
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
),
cohort_sizes AS (
    SELECT cohort_quarter, COUNT(DISTINCT customer_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_quarter
)
SELECT
    cc.cohort_quarter,
    cs.cohort_size,
    cc.order_quarter,
    COUNT(DISTINCT cc.customer_id)                                     AS active_customers,
    ROUND(COUNT(DISTINCT cc.customer_id) * 100.0 / cs.cohort_size, 1) AS retention_rate_pct
FROM customer_cohorts cc
JOIN cohort_sizes cs ON cc.cohort_quarter = cs.cohort_quarter
GROUP BY cc.cohort_quarter, cs.cohort_size, cc.order_quarter
ORDER BY cc.cohort_quarter, cc.order_quarter;
```

**What this tells us:** For each customer cohort (grouped by the quarter they joined), we track what % came back to purchase in each subsequent quarter. A declining retention rate is normal — the steepness of that decline tells you how strong your product-market fit and retention mechanics are.

---

## 💡 Sample Query — Anomaly Detection: Outlier Orders (Q14)

```sql
WITH order_values AS (
    SELECT o.order_id, o.customer_id, o.order_date,
           ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100)), 2) AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY o.order_id, o.customer_id, o.order_date
),
stats AS (
    SELECT AVG(order_value) AS mean_value, STDDEV(order_value) AS std_value
    FROM order_values
)
SELECT ov.order_id, ov.customer_id, ov.order_value,
       ROUND((ov.order_value - s.mean_value) / NULLIF(s.std_value, 0), 2) AS z_score
FROM order_values ov, stats s
WHERE ABS((ov.order_value - s.mean_value) / NULLIF(s.std_value, 0)) > 1.5
ORDER BY z_score DESC;
```

**What this tells us:** Orders more than 1.5 standard deviations from the mean warrant review. Flagging Z-score > 2 is standard practice in fraud detection and operational analytics.

---

## 🔍 Key Business Insights from the Analysis

1. **VIP customers drive disproportionate revenue** — Q4 shows them spending 3–4x more per order than New customers. Retention spend on VIPs yields highest ROI.

2. **Home Decor outperforms on volume; Textiles outperforms on value** — different optimisation strategies needed per category.

3. **Q4 seasonal spike is consistent** — inventory planning should front-load Textiles and Home Decor in October.

4. **Discount bands above 10% do not proportionally increase order volume** — a 5% cap on routine discounts is recommended. Reserve 10%+ for clearance only.

5. **Cohort retention drops ~40% quarter-on-quarter** — industry average for e-commerce is 30–40%, suggesting retention is within range but email re-engagement could recover an additional 5–8%.

---

## 🛠️ How to Run

1. Install PostgreSQL (or use [DB Fiddle](https://www.db-fiddle.com/) online)
2. Run `schema_and_data.sql` to create tables and load sample data
3. Run any query from `analysis_queries.sql`
4. Each query includes a `/* INSIGHT */` block explaining the business interpretation

---

## 📁 Files

```
├── README.md               ← This file
├── schema_and_data.sql     ← Table definitions + sample data
└── analysis_queries.sql    ← All 18 business queries with comments
```

---

## 🔗 Related Projects

- **Customer Churn Prediction** (Python + XGBoost) — *in progress*
- **UK Retail Sales Dashboard** (Power BI + ONS data) — *in progress*

---


