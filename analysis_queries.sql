-- ============================================================
-- E-COMMERCE BUSINESS INTELLIGENCE CASE STUDY
-- 18 SQL Queries Answering Real Business Questions
-- Author: Naga Jyothi Chavali | MSc Business Analytics, University of Edinburgh
-- Dataset: UK Online Retail (schema in schema_and_data.sql)
-- ============================================================


-- ══════════════════════════════════════════════════════════════
-- SECTION 1: REVENUE ANALYSIS
-- ══════════════════════════════════════════════════════════════

-- ── Query 1: Total Revenue by Month ──────────────────────────
-- Business question: How is revenue trending month-on-month across 2023?

SELECT
    TO_CHAR(o.order_date, 'YYYY-MM')                            AS month,
    COUNT(DISTINCT o.order_id)                                  AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY TO_CHAR(o.order_date, 'YYYY-MM')
ORDER BY month;

/*
INSIGHT: Monthly revenue trend reveals seasonality — Q4 typically spikes
due to holiday gifting. A declining mid-year followed by Q4 recovery is
the expected pattern for UK home goods retail.
*/


-- ── Query 2: Revenue by Product Category ─────────────────────
-- Business question: Which product categories drive the most revenue?

SELECT
    p.category,
    COUNT(DISTINCT oi.order_id)                                         AS orders_containing_category,
    SUM(oi.quantity)                                                    AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS total_revenue,
    ROUND(AVG(oi.unit_price), 2)                                        AS avg_unit_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o   ON oi.order_id   = o.order_id
WHERE o.status = 'Completed'
GROUP BY p.category
ORDER BY total_revenue DESC;

/*
INSIGHT: High-revenue categories warrant increased stock investment.
Low-revenue but high-volume categories may need margin review.
*/


-- ── Query 3: Year-on-Year Revenue Growth (Monthly) ───────────
-- Business question: Are we growing or declining vs last year?

WITH monthly_revenue AS (
    SELECT
        EXTRACT(YEAR  FROM o.order_date) AS yr,
        EXTRACT(MONTH FROM o.order_date) AS mth,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date)
)
SELECT
    curr.yr,
    curr.mth,
    curr.revenue                                                            AS current_revenue,
    prev.revenue                                                            AS prev_year_revenue,
    ROUND((curr.revenue - prev.revenue) / NULLIF(prev.revenue, 0) * 100, 1) AS yoy_growth_pct
FROM monthly_revenue curr
LEFT JOIN monthly_revenue prev
    ON curr.mth = prev.mth AND curr.yr = prev.yr + 1
ORDER BY curr.yr, curr.mth;

/*
INSIGHT: Positive YoY% = growth; negative = contraction.
Months where prev_year_revenue is NULL have no comparable period yet.
*/


-- ── Query 4: Revenue Contribution by Customer Segment ────────
-- Business question: Do VIP customers justify their acquisition cost?

SELECT
    c.customer_segment,
    COUNT(DISTINCT c.customer_id)                                        AS customers,
    COUNT(DISTINCT o.order_id)                                           AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100)), 2) AS total_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100))
          / COUNT(DISTINCT c.customer_id), 2)                            AS revenue_per_customer
FROM customers c
JOIN orders o     ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id  = oi.order_id
WHERE o.status = 'Completed'
GROUP BY c.customer_segment
ORDER BY revenue_per_customer DESC;

/*
INSIGHT: VIP customers should show significantly higher revenue_per_customer.
If not, loyalty tiers need redesigning.
*/


-- ══════════════════════════════════════════════════════════════
-- SECTION 2: CUSTOMER BEHAVIOUR ANALYSIS
-- ══════════════════════════════════════════════════════════════

-- ── Query 5: Customer Lifetime Value (CLV) ───────────────────
-- Business question: Who are our most valuable customers?

SELECT
    c.customer_id,
    c.country,
    c.customer_segment,
    COUNT(DISTINCT o.order_id)                                           AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100)), 2) AS lifetime_value,
    MIN(o.order_date)                                                    AS first_order,
    MAX(o.order_date)                                                    AS last_order,
    MAX(o.order_date) - MIN(o.order_date)                                AS customer_lifespan_days
FROM customers c
JOIN orders o      ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id   = oi.order_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.country, c.customer_segment
ORDER BY lifetime_value DESC;

/*
INSIGHT: Top 20% of customers typically generate 80% of revenue (Pareto principle).
High CLV + long lifespan = core retention target.
*/


-- ── Query 6: Average Order Value (AOV) by Country ────────────
-- Business question: Which markets spend most per order?

SELECT
    c.country,
    COUNT(DISTINCT o.order_id)                                                AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100)), 2)   AS total_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100))
          / COUNT(DISTINCT o.order_id), 2)                                    AS avg_order_value
FROM customers c
JOIN orders o      ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id   = oi.order_id
WHERE o.status = 'Completed'
GROUP BY c.country
ORDER BY avg_order_value DESC;

/*
INSIGHT: High-AOV markets warrant localised marketing investment.
Low-AOV markets may respond better to bundle promotions.
*/


-- ── Query 7: Customer Purchase Frequency Distribution ────────
-- Business question: How many customers are one-time vs repeat buyers?

SELECT
    order_frequency,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_customers
FROM (
    SELECT
        c.customer_id,
        COUNT(DISTINCT o.order_id) AS order_frequency
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id
) freq
GROUP BY order_frequency
ORDER BY order_frequency;

/*
INSIGHT: A high % of one-time buyers signals a retention problem.
Benchmark: healthy e-commerce repeat rate = 25–40%.
*/


-- ── Query 8: Cohort Retention Analysis ───────────────────────
-- Business question: Of customers who joined each quarter, how many came back the next quarter?

WITH customer_cohorts AS (
    SELECT
        c.customer_id,
        DATE_TRUNC('quarter', c.signup_date)::DATE    AS cohort_quarter,
        DATE_TRUNC('quarter', o.order_date)::DATE     AS order_quarter
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
    COUNT(DISTINCT cc.customer_id)                                             AS active_customers,
    ROUND(COUNT(DISTINCT cc.customer_id) * 100.0 / cs.cohort_size, 1)         AS retention_rate_pct
FROM customer_cohorts cc
JOIN cohort_sizes cs ON cc.cohort_quarter = cs.cohort_quarter
GROUP BY cc.cohort_quarter, cs.cohort_size, cc.order_quarter
ORDER BY cc.cohort_quarter, cc.order_quarter;

/*
INSIGHT: Declining retention_rate_pct over time = normal churn.
Flat or rising rates = strong loyalty programme or product-market fit.
*/


-- ══════════════════════════════════════════════════════════════
-- SECTION 3: PRODUCT PERFORMANCE
-- ══════════════════════════════════════════════════════════════

-- ── Query 9: Top 10 Products by Revenue ──────────────────────
-- Business question: Which products should we prioritise for stock and marketing?

SELECT
    p.product_id,
    p.description,
    p.category,
    SUM(oi.quantity)                                                       AS total_units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100)), 2) AS total_revenue,
    ROUND(AVG(oi.discount_pct), 1)                                         AS avg_discount_given
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o   ON oi.order_id   = o.order_id
WHERE o.status = 'Completed'
GROUP BY p.product_id, p.description, p.category
ORDER BY total_revenue DESC
LIMIT 10;

/*
INSIGHT: High revenue + low discount = most profitable SKUs.
High revenue + high discount = volume-driven but margin-thin.
*/


-- ── Query 10: Product Affinity (Frequently Bought Together) ──
-- Business question: Which product pairs appear in the same order most often?

SELECT
    a.product_id         AS product_a,
    pa.description       AS product_a_name,
    b.product_id         AS product_b,
    pb.description       AS product_b_name,
    COUNT(*)             AS times_bought_together
FROM order_items a
JOIN order_items b  ON a.order_id = b.order_id AND a.product_id < b.product_id
JOIN products pa    ON a.product_id = pa.product_id
JOIN products pb    ON b.product_id = pb.product_id
JOIN orders o       ON a.order_id   = o.order_id
WHERE o.status = 'Completed'
GROUP BY a.product_id, pa.description, b.product_id, pb.description
ORDER BY times_bought_together DESC
LIMIT 10;

/*
INSIGHT: High-affinity pairs = bundle opportunity.
E.g. Mug Set + Scented Candle = "Gift Set" marketing angle.
*/


-- ── Query 11: Low-Performing Products (Candidates for Removal) ─
-- Business question: Which products are barely selling and dragging inventory?

SELECT
    p.product_id,
    p.description,
    p.category,
    COALESCE(SUM(oi.quantity), 0)                                          AS total_units_sold,
    COALESCE(ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100)), 2), 0) AS total_revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o       ON oi.order_id  = o.order_id AND o.status = 'Completed'
GROUP BY p.product_id, p.description, p.category
HAVING COALESCE(SUM(oi.quantity), 0) < 5
ORDER BY total_units_sold ASC;

/*
INSIGHT: Products with very low sales volumes should be reviewed.
Consider: discontinue, discount to clear, or reposition with better marketing.
*/


-- ══════════════════════════════════════════════════════════════
-- SECTION 4: OPERATIONAL & ANOMALY ANALYSIS
-- ══════════════════════════════════════════════════════════════

-- ── Query 12: Cancellation and Return Rate by Month ──────────
-- Business question: Are cancellations or returns increasing — and when?

SELECT
    TO_CHAR(order_date, 'YYYY-MM')                              AS month,
    COUNT(*)                                                    AS total_orders,
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END)      AS cancellations,
    SUM(CASE WHEN status = 'Returned'  THEN 1 ELSE 0 END)      AS returns,
    ROUND(SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                AS cancellation_rate_pct,
    ROUND(SUM(CASE WHEN status = 'Returned'  THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                AS return_rate_pct
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY month;

/*
INSIGHT: A spike in a specific month = trigger event (new product, shipping issue).
Industry benchmark: return rate <10%, cancellation rate <5% for UK e-commerce.
*/


-- ── Query 13: Revenue Lost to Cancellations and Returns ──────
-- Business question: How much revenue are we losing to bad orders?

SELECT
    o.status,
    COUNT(DISTINCT o.order_id)                                             AS order_count,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100)), 2) AS revenue_at_risk
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status IN ('Cancelled', 'Returned')
GROUP BY o.status;

/*
INSIGHT: Revenue at risk from returns/cancellations should be tracked weekly.
High returned revenue in a specific category = quality or description mismatch.
*/


-- ── Query 14: Anomaly Detection — Orders with Unusually High Value ──
-- Business question: Which orders are statistical outliers (potential fraud or bulk buyers)?

WITH order_values AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100)), 2) AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY o.order_id, o.customer_id, o.order_date
),
stats AS (
    SELECT
        AVG(order_value)    AS mean_value,
        STDDEV(order_value) AS std_value
    FROM order_values
)
SELECT
    ov.order_id,
    ov.customer_id,
    ov.order_date,
    ov.order_value,
    ROUND((ov.order_value - s.mean_value) / NULLIF(s.std_value, 0), 2) AS z_score
FROM order_values ov, stats s
WHERE ABS((ov.order_value - s.mean_value) / NULLIF(s.std_value, 0)) > 1.5
ORDER BY z_score DESC;

/*
INSIGHT: Z-score > 2 = statistically unusual. Investigate for fraud or bulk order handling.
Z-score < -2 = suspiciously small — could be test orders or data quality issues.
*/


-- ── Query 15: Discount Impact on Revenue ─────────────────────
-- Business question: Are discounts generating volume or just eroding margin?

SELECT
    CASE
        WHEN oi.discount_pct = 0        THEN 'No Discount'
        WHEN oi.discount_pct BETWEEN 1 AND 9  THEN '1–9%'
        WHEN oi.discount_pct BETWEEN 10 AND 19 THEN '10–19%'
        ELSE '20%+'
    END                                                              AS discount_band,
    COUNT(DISTINCT oi.order_id)                                      AS orders,
    SUM(oi.quantity)                                                 AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)                       AS gross_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100)), 2) AS net_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * oi.discount_pct/100), 2) AS discount_given
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'Completed'
GROUP BY discount_band
ORDER BY gross_revenue DESC;

/*
INSIGHT: If heavily discounted items show higher volume but lower net revenue,
discounts are buying volume not profit. Recommend testing smaller discount tiers.
*/


-- ══════════════════════════════════════════════════════════════
-- SECTION 5: ADVANCED / WINDOW FUNCTIONS
-- ══════════════════════════════════════════════════════════════

-- ── Query 16: Running Revenue Total (Cumulative) ─────────────
-- Business question: Track cumulative revenue against monthly targets.

SELECT
    TO_CHAR(o.order_date, 'YYYY-MM')                                         AS month,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100)), 2)   AS monthly_revenue,
    ROUND(SUM(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100)))
          OVER (ORDER BY TO_CHAR(o.order_date, 'YYYY-MM')), 2)               AS cumulative_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY TO_CHAR(o.order_date, 'YYYY-MM')
ORDER BY month;

/*
INSIGHT: Cumulative revenue tracks pacing to annual targets.
Ideal usage: overlay on a Power BI line chart with target benchmark line.
*/


-- ── Query 17: Customer Ranking by Revenue (DENSE_RANK) ───────
-- Business question: Rank customers within each segment by spend.

SELECT
    c.customer_id,
    c.customer_segment,
    c.country,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100)), 2) AS total_spend,
    DENSE_RANK() OVER (
        PARTITION BY c.customer_segment
        ORDER BY SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100)) DESC
    ) AS rank_within_segment
FROM customers c
JOIN orders o      ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id   = oi.order_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.customer_segment, c.country
ORDER BY c.customer_segment, rank_within_segment;

/*
INSIGHT: Rank 1 within each segment = top loyalty target.
VIP Rank 1 = highest-value customer in the entire business.
*/


-- ── Query 18: Month-over-Month Revenue Change (LAG Function) ──
-- Business question: Which months saw the biggest revenue swings?

WITH monthly AS (
    SELECT
        TO_CHAR(o.order_date, 'YYYY-MM') AS month,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct/100)), 2) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY TO_CHAR(o.order_date, 'YYYY-MM')
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month)                                     AS prev_month_revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY month), 2)                 AS mom_change,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month))
          / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100, 1)        AS mom_growth_pct
FROM monthly
ORDER BY month;

/*
INSIGHT: Large positive MoM% = marketing spike or seasonal event.
Large negative MoM% = investigate: pricing change, stock issue, competitor action.
*/
