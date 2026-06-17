use olist_customers;


--- Step 1: Calculate CLV for each customer

CREATE VIEW vw_clv AS
SELECT
    cs.customer_unique_id,
    COUNT(DISTINCT os.order_id) AS total_orders,
    ROUND(SUM(ois.price + ois.freight_value), 2) AS customer_lifetime_value
FROM customers_staging cs
JOIN orders_staging os
    ON cs.customer_id = os.customer_id
JOIN order_items_staging ois
    ON os.order_id = ois.order_id
GROUP BY cs.customer_unique_id;

--- Step 2: Top Customers by CLV

SELECT *
FROM vw_clv
ORDER BY customer_lifetime_value DESC
LIMIT 20;

--- Step 3: Average Customer Lifetime Value

SELECT
    ROUND(AVG(customer_lifetime_value), 2) AS avg_clv
FROM vw_clv; 

--- Step 4: CLV Distribution

SELECT
    CASE
        WHEN customer_lifetime_value >= 1000 THEN 'High Value'
        WHEN customer_lifetime_value >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_type,
    COUNT(*) AS total_customers
FROM vw_clv
GROUP BY customer_type
ORDER BY total_customers DESC;

--- Step 5: CLV by RFM Segment ⭐ This is the strongest CLV analysis.

SELECT
    vcs.customer_segment,
    COUNT(*) AS total_customers,
    ROUND(AVG(vc.customer_lifetime_value), 2) AS avg_clv,
    ROUND(SUM(vc.customer_lifetime_value), 2) AS total_clv
FROM vw_customer_segments vcs
JOIN vw_clv vc
    ON vcs.customer_unique_id = vc.customer_unique_id
GROUP BY vcs.customer_segment
ORDER BY total_clv DESC;

