use olist_customers;

-- 06_Cohort_Retention_Churn.sql
--- │
--- ├── Customer Cohorts
--- ├── Retention Analysis
--- ├── Churn Analysis
--- └── Cohort Matrix

--- question 1: Find each customer’s first purchase month

SELECT
    cs.customer_unique_id,
    MIN(os.order_purchase_timestamp) AS first_purchase_date
FROM customers_staging cs
JOIN orders_staging os
    ON cs.customer_id = os.customer_id
GROUP BY cs.customer_unique_id;


--- question 2: Find each customer’s purchase months

SELECT
    cs.customer_unique_id,
    DATE_FORMAT(os.order_purchase_timestamp, '%Y-%m') AS purchase_month
FROM customers_staging cs
JOIN orders_staging os
    ON cs.customer_id = os.customer_id
GROUP BY 
    cs.customer_unique_id,
    DATE_FORMAT(os.order_purchase_timestamp, '%Y-%m');
    
--- question 3: Create Cohort Month + Purchase Month

WITH customer_cohort AS (
    SELECT
        cs.customer_unique_id,
        DATE_FORMAT(MIN(os.order_purchase_timestamp), '%Y-%m') AS cohort_month
    FROM customers_staging cs
    JOIN orders_staging os
        ON cs.customer_id = os.customer_id
    GROUP BY cs.customer_unique_id
),
customer_purchases AS (
    SELECT
        cs.customer_unique_id,
        DATE_FORMAT(os.order_purchase_timestamp, '%Y-%m') AS purchase_month
    FROM customers_staging cs
    JOIN orders_staging os
        ON cs.customer_id = os.customer_id
    GROUP BY
        cs.customer_unique_id,
        DATE_FORMAT(os.order_purchase_timestamp, '%Y-%m')
)
SELECT
    cc.customer_unique_id,
    cc.cohort_month,
    cp.purchase_month
FROM customer_cohort cc
JOIN customer_purchases cp
    ON cc.customer_unique_id = cp.customer_unique_id;
    
--- question 4: Calculate Cohort Index

WITH customer_cohort AS (
    SELECT
        cs.customer_unique_id,
        DATE_FORMAT(MIN(os.order_purchase_timestamp), '%Y-%m') AS cohort_month
    FROM customers_staging cs
    JOIN orders_staging os
        ON cs.customer_id = os.customer_id
    GROUP BY cs.customer_unique_id
),
customer_purchases AS (
    SELECT
        cs.customer_unique_id,
        DATE_FORMAT(os.order_purchase_timestamp, '%Y-%m') AS purchase_month
    FROM customers_staging cs
    JOIN orders_staging os
        ON cs.customer_id = os.customer_id
    GROUP BY
        cs.customer_unique_id,
        DATE_FORMAT(os.order_purchase_timestamp, '%Y-%m')
)
SELECT
    cc.customer_unique_id,
    cc.cohort_month,
    cp.purchase_month,
   (
    (YEAR(STR_TO_DATE(CONCAT(cp.purchase_month, '-01'), '%Y-%m-%d'))
     - YEAR(STR_TO_DATE(CONCAT(cc.cohort_month, '-01'), '%Y-%m-%d'))) * 12
    +
    (MONTH(STR_TO_DATE(CONCAT(cp.purchase_month, '-01'), '%Y-%m-%d'))
     - MONTH(STR_TO_DATE(CONCAT(cc.cohort_month, '-01'), '%Y-%m-%d')))
) AS cohort_index
FROM customer_cohort cc
JOIN customer_purchases cp
    ON cc.customer_unique_id = cp.customer_unique_id;
    
--- next step Count customers by cohort_month and cohort_index

CREATE VIEW vw_cohort_data AS
WITH customer_cohort AS (
    SELECT
        cs.customer_unique_id,
        DATE_FORMAT(MIN(os.order_purchase_timestamp), '%Y-%m') AS cohort_month
    FROM customers_staging cs
    JOIN orders_staging os
        ON cs.customer_id = os.customer_id
    GROUP BY cs.customer_unique_id
),
customer_purchases AS (
    SELECT
        cs.customer_unique_id,
        DATE_FORMAT(os.order_purchase_timestamp, '%Y-%m') AS purchase_month
    FROM customers_staging cs
    JOIN orders_staging os
        ON cs.customer_id = os.customer_id
    GROUP BY
        cs.customer_unique_id,
        DATE_FORMAT(os.order_purchase_timestamp, '%Y-%m')
)
SELECT
    cc.customer_unique_id,
    cc.cohort_month,
    cp.purchase_month,
    (
        (YEAR(STR_TO_DATE(CONCAT(cp.purchase_month, '-01'), '%Y-%m-%d'))
        - YEAR(STR_TO_DATE(CONCAT(cc.cohort_month, '-01'), '%Y-%m-%d'))) * 12
        +
        (MONTH(STR_TO_DATE(CONCAT(cp.purchase_month, '-01'), '%Y-%m-%d'))
        - MONTH(STR_TO_DATE(CONCAT(cc.cohort_month, '-01'), '%Y-%m-%d')))
    ) AS cohort_index
FROM customer_cohort cc
JOIN customer_purchases cp
    ON cc.customer_unique_id = cp.customer_unique_id;
    
SELECT *
FROM vw_cohort_data
LIMIT 20;

SELECT
    cohort_month,
    cohort_index,
    COUNT(DISTINCT customer_unique_id) AS total_customers
FROM vw_cohort_data
GROUP BY cohort_month, cohort_index
ORDER BY cohort_month, cohort_index;

--- Next Step: Calculate Retention Rate

WITH cohort_counts AS (
    SELECT
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_unique_id) AS total_customers
    FROM vw_cohort_data
    GROUP BY cohort_month, cohort_index
)
SELECT
    cohort_month,
    cohort_index,
    total_customers,
    ROUND(
        total_customers * 100.0 /
        FIRST_VALUE(total_customers)
            OVER (
                PARTITION BY cohort_month
                ORDER BY cohort_index
            ),
        2
    ) AS retention_rate
FROM cohort_counts
ORDER BY cohort_month, cohort_index;


--- next step : Churn Rate Analysis


WITH cohort_counts AS (
    SELECT
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_unique_id) AS total_customers
    FROM vw_cohort_data
    GROUP BY cohort_month, cohort_index
)
SELECT
    cohort_month,
    cohort_index,
    total_customers,
    ROUND(
        total_customers * 100.0 /
        FIRST_VALUE(total_customers)
        OVER (
            PARTITION BY cohort_month
            ORDER BY cohort_index
        ),
        2
    ) AS retention_rate,
    ROUND(
        100 -
        (
            total_customers * 100.0 /
            FIRST_VALUE(total_customers)
            OVER (
                PARTITION BY cohort_month
                ORDER BY cohort_index
            )
        ),
        2
    ) AS churn_rate
FROM cohort_counts
ORDER BY cohort_month, cohort_index;


--- next step: Final Cohort Summary

WITH cohort_counts AS (
    SELECT
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_unique_id) AS total_customers
    FROM vw_cohort_data
    GROUP BY cohort_month, cohort_index
),
cohort_size AS (
    SELECT
        cohort_month,
        total_customers AS cohort_customers
    FROM cohort_counts
    WHERE cohort_index = 0
)
SELECT
    cc.cohort_month,
    ROUND(
        cc.total_customers * 100.0 / cs.cohort_customers,
        2
    ) AS month1_retention
FROM cohort_counts cc
JOIN cohort_size cs
    ON cc.cohort_month = cs.cohort_month
WHERE cc.cohort_index = 1
ORDER BY month1_retention DESC;


