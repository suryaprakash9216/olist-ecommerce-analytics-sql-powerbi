use olist_customers;

--- question 1: What is the latest purchase date in orders_staging? (R)

select max(order_purchase_timestamp)
from orders_staging;
 
--- question 2: How would you calculate Frequency? (Frequency)=Number of Orders

 select COUNT(DISTINCT order_id)
 from orders_staging;
 
 --- question 3: This is the foundation of the entire RFM analysis.
 
 select cs.customer_unique_id, datediff('2018-10-18',max(os.order_purchase_timestamp)) as recency ,
 COUNT(DISTINCT os.order_id)  as frequency ,
 sum(ois.price + ois.freight_value) as monetary
 from customers_staging cs
 join orders_staging os on cs.customer_id = os.customer_id
 join order_items_staging ois on os.order_id = ois.order_id
 group by cs.customer_unique_id;
 
 
 --- question 4: Create RFM scores
 
 WITH rfm AS (
    SELECT
        cs.customer_unique_id,
        DATEDIFF('2018-10-18', MAX(os.order_purchase_timestamp)) AS recency,
        COUNT(DISTINCT os.order_id) AS frequency,
        ROUND(SUM(ois.price + ois.freight_value), 2) AS monetary
    FROM customers_staging cs
    JOIN orders_staging os
        ON cs.customer_id = os.customer_id
    JOIN order_items_staging ois
        ON os.order_id = ois.order_id
    GROUP BY cs.customer_unique_id
)
SELECT *,
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency) AS f_score,
    NTILE(5) OVER (ORDER BY monetary) AS m_score
FROM rfm;

--- question 5: Now create a combined RFM score.
 
 WITH rfm AS (
    SELECT
        cs.customer_unique_id,
        DATEDIFF('2018-10-18', MAX(os.order_purchase_timestamp)) AS recency,
        COUNT(DISTINCT os.order_id) AS frequency,
        ROUND(SUM(ois.price + ois.freight_value), 2) AS monetary
    FROM customers_staging cs
    JOIN orders_staging os
        ON cs.customer_id = os.customer_id
    JOIN order_items_staging ois
        ON os.order_id = ois.order_id
    GROUP BY cs.customer_unique_id
),
rfm_scores AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm
)
SELECT
    *,
    CONCAT(r_score, f_score, m_score) AS rfm_score
FROM rfm_scores;
 
 
 
 --- question 6: Customer Segmentation --- We convert RFM scores into business segments.
 
 WITH rfm AS (
    SELECT
        cs.customer_unique_id,
        DATEDIFF('2018-10-18', MAX(os.order_purchase_timestamp)) AS recency,
        COUNT(DISTINCT os.order_id) AS frequency,
        ROUND(SUM(ois.price + ois.freight_value), 2) AS monetary
    FROM customers_staging cs
    JOIN orders_staging os
        ON cs.customer_id = os.customer_id
    JOIN order_items_staging ois
        ON os.order_id = ois.order_id
    GROUP BY cs.customer_unique_id
),
rfm_scores AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm
)
SELECT
    *,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
            THEN 'Champions'

        WHEN r_score >= 3 AND f_score >= 4
            THEN 'Loyal Customers'

        WHEN r_score >= 4 AND f_score >= 2
            THEN 'Potential Loyalists'

        WHEN r_score <= 2 AND f_score >= 3
            THEN 'At Risk'

        ELSE 'Lost Customers'
    END AS customer_segment
FROM rfm_scores;


--- question 7:  create view

USE olist_customers;

-- 05_Customer_Segmentation_RFM
-- Goal: create RFM scores and customer segments


-- Create RFM customer segment view

DROP VIEW IF EXISTS vw_customer_segments;

CREATE VIEW vw_customer_segments AS
WITH rfm AS (
    SELECT
        cs.customer_unique_id,
        DATEDIFF('2018-10-18', MAX(os.order_purchase_timestamp)) AS recency,
        COUNT(DISTINCT os.order_id) AS frequency,
        ROUND(SUM(ois.price + ois.freight_value), 2) AS monetary
    FROM customers_staging cs
    JOIN orders_staging os
        ON cs.customer_id = os.customer_id
    JOIN order_items_staging ois
        ON os.order_id = ois.order_id
    GROUP BY cs.customer_unique_id
),
rfm_scores AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm
)
SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
            THEN 'Champions'

        WHEN r_score >= 3 AND f_score >= 4
            THEN 'Loyal Customers'

        WHEN r_score >= 4 AND f_score >= 2
            THEN 'Potential Loyalists'

        WHEN r_score <= 2 AND f_score >= 3
            THEN 'At Risk'

        ELSE 'Lost Customers'
    END AS customer_segment
FROM rfm_scores;


--- Next analysis codes
--- 1. Check the segment view

SELECT *
FROM vw_customer_segments
LIMIT 20;

--- 2. Count customers by segment

SELECT
    customer_segment,
    COUNT(*) AS total_customers
FROM vw_customer_segments
GROUP BY customer_segment
ORDER BY total_customers DESC;

--- 3. Revenue by segment

SELECT
    customer_segment,
    COUNT(*) AS total_customers,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(AVG(monetary), 2) AS avg_customer_value
FROM vw_customer_segments
GROUP BY customer_segment
ORDER BY total_revenue DESC;

--- 4. Average RFM metrics by segment

SELECT
    customer_segment,
    ROUND(AVG(recency), 2) AS avg_recency,
    ROUND(AVG(frequency), 2) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary
FROM vw_customer_segments
GROUP BY customer_segment
ORDER BY avg_monetary DESC;

--- Top customers by RFM score 

SELECT *
FROM vw_customer_segments
ORDER BY r_score DESC, f_score DESC, m_score DESC, monetary DESC
LIMIT 20;




 