CREATE VIEW rfm_segments AS
WITH order_payments AS (
    SELECT order_id, SUM(payment_value) AS order_total
    FROM payments
    GROUP BY order_id
),

customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        op.order_total
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_payments op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31'
),

reference_date AS (
    SELECT MAX(order_purchase_timestamp) AS ref_date
    FROM customer_orders
),

rfm_raw AS (
    SELECT
        co.customer_unique_id,
        DATEDIFF(MAX(rd.ref_date), MAX(co.order_purchase_timestamp)) AS recency_days,
        COUNT(DISTINCT co.order_id) AS frequency,
        SUM(co.order_total) AS monetary
    FROM customer_orders co
    CROSS JOIN reference_date rd
    GROUP BY co.customer_unique_id
),

rfm_scored AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        6 - NTILE(5) OVER (ORDER BY recency_days) AS r_score,
        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 3
            WHEN frequency >= 3 THEN 5
        END AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm_raw
)

SELECT
    customer_unique_id,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary,
    r_score,
    f_score,
    m_score,
    CASE
        WHEN frequency >= 3 AND r_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN frequency >= 3 AND r_score <= 2 THEN 'At Risk (Loyal)'
        WHEN r_score >= 4 AND m_score >= 4 THEN 'Big Spenders (New)'
        WHEN r_score >= 4 AND m_score <= 2 THEN 'New / Low Value'
        WHEN r_score >= 4 THEN 'Recent Customers'
        WHEN r_score <= 2 AND m_score >= 4 THEN 'At Risk (High Value)'
        WHEN r_score <= 2 AND m_score <= 2 THEN 'Lost'
        WHEN r_score = 3 AND m_score >= 4 THEN 'Moderate Recency, High Value'
        WHEN r_score = 3 AND m_score <= 2 THEN 'Moderate Recency, Low Value'
        ELSE 'Standard'
    END AS segment
FROM rfm_scored;