CREATE VIEW rfm_segments_by_state AS
SELECT
    c.customer_state,
    r.segment,
    COUNT(*) AS num_customers,
    ROUND(AVG(r.monetary), 2) AS avg_monetary
FROM rfm_segments r
JOIN customers c ON r.customer_unique_id = c.customer_unique_id
GROUP BY c.customer_state, r.segment
ORDER BY c.customer_state, num_customers DESC;