use olist_customers;

--- Step 1: Business Overview KPIs ---
--- 1. Total Orders --- yes
--- 2. Total Customers --- yes
--- 3. Total Sellers
--- 4. Total Products
--- 5. Total Revenue --- yes 
--- 6. Average Order Value (AOV)
--- 7. Total Product Categories
--- 8. Total Items Sold
--- 9. Average Review Score
--- 10. Order Delivery Rate (% Delivered Orders)

--- 1. Total Revenue     
--- 2. Total Orders
--- 3. Total Customers
--- 4. Average Order Value
--- 5. Average Review Score
--- Business size
--- Sales activity
--- Customer base
--- Customer spending
--- Customer satisfaction

--- KPIs
--- 1. Total Revenue   

select round(sum(price + freight_value ),2)as Total_revenue 
from order_items_staging;

--- 2. Total Orders

select count(distinct order_id) as  Total_Orders
from orders_staging;

--- 3. Total Customers

select count(distinct customer_unique_id) as Total_customers
from customers_staging;

--- 4. Average Order Value

select  round((round(sum(ot.price + ot.freight_value ),2) /count(distinct o.order_id)),2) as Average_Order_Value
from orders_staging o
join order_items_staging ot on o.order_id = ot.order_id;

--- 5. Average Review Score

select avg(review_score) as Average_Review_Score
from order_reviews_staging;

--- Step 2: Order Analysis

--- Q1. Order Status Distribution
--- Q2. Average Delivery Lead Time
--- Q3. Estimated vs Actual Delivery Date
--- Q4. Order Volume Trend Over Time
--- Q5. Highest & Lowest Order Volume Months

select * 
from orders_staging
limit 5;

--- Question 1: What is the distribution of order statuses, and what percentage of orders were successfully delivered?

select 
      order_status, 
      count(*) as total_orders,
      round( count(*) *100.0/(SELECT COUNT(*) FROM orders_staging),2) as percentage_orders 
from orders_staging
group by order_status
order by total_orders desc;

--- Question 2: What is the average delivery lead time between order purchase and customer delivery?

SELECT
    round(avg(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)),2) AS avg_delivery_lead_time_days
FROM orders_staging
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL; 
  
  --- question 3: What is the average difference between the estimated delivery date and the actual delivery date?
  
  select round(avg(datediff( order_delivered_customer_date,order_estimated_delivery_date)),2) AS avg_delivery_delay_days
  from orders_staging
  WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL; 
  
  --- Question 4: How has order volume changed over time?
  
  select DATE_FORMAT(order_purchase_timestamp, '%Y-%m') as years_months, COUNT(DISTINCT order_id) as orders
  from orders_staging
  group by DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
  order by years_months;
  
  --- Question 5: Which months had the highest and lowest order volumes?
  
select DATE_FORMAT(order_purchase_timestamp, '%Y-%m') as years_months, COUNT(DISTINCT order_id) as orders
  from orders_staging
  group by DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
  order by orders desc
  limit 3;
  
  
  select DATE_FORMAT(order_purchase_timestamp, '%Y-%m') as years_months, COUNT(DISTINCT order_id) as orders
  from orders_staging
  group by DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
  order by orders asc
  limit 3;
  
  --- or 
  
  WITH monthly_orders AS (
    SELECT 
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS years_months,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders_staging
    GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
),
ranked_orders AS (
    SELECT *,
           RANK() OVER (ORDER BY total_orders DESC) AS highest_rank,
           RANK() OVER (ORDER BY total_orders ASC) AS lowest_rank
    FROM monthly_orders
)
SELECT *
FROM ranked_orders
WHERE highest_rank <= 5
   OR lowest_rank <= 5
ORDER BY total_orders DESC;
  
  
  
  --- step 3: Revenue Analysis
  
  ---  question 1: How has revenue changed over time? or Are sales growing or declining?
  
  select date_format(os.order_purchase_timestamp,'%Y-%m') as years_months,
  round(sum(ois.price+ois.freight_value),2) as total_revenue
  from order_items_staging ois
  join orders_staging os on ois.order_id = os.order_id
  group by  date_format(os.order_purchase_timestamp,'%Y-%m') 
  order by 1;
  
  --- question 2:Which months generated the highest and lowest revenue?
  
    select date_format(os.order_purchase_timestamp,'%Y-%m') as years_months,
  round(sum(ois.price+ois.freight_value),2) as total_revenue
  from order_items_staging ois
  join orders_staging os on ois.order_id = os.order_id
  group by  date_format(os.order_purchase_timestamp,'%Y-%m') 
  order by 2 desc
  limit 3;
  
    select date_format(os.order_purchase_timestamp,'%Y-%m') as years_months,
  round(sum(ois.price+ois.freight_value),2) as total_revenue
  from order_items_staging ois
  join orders_staging os on ois.order_id = os.order_id
  group by  date_format(os.order_purchase_timestamp,'%Y-%m') 
  order by 2 asc
  limit 3;
  
  --- question 3: Which product categories generate the most revenue?
  
  SELECT
    ps.product_category_name AS product_category,
    ROUND(SUM(ois.price + ois.freight_value), 2) AS total_revenue
FROM order_items_staging ois
JOIN products_staging ps
    ON ois.product_id = ps.product_id
GROUP BY ps.product_category_name
ORDER BY total_revenue DESC;

--- question 4: Which states generate the most revenue?

SELECT
    cs.customer_state AS state_name,
    ROUND(SUM(ois.price + ois.freight_value), 2) AS total_revenue
FROM order_items_staging ois
JOIN orders_staging os
    ON ois.order_id = os.order_id
JOIN customers_staging cs
    ON os.customer_id = cs.customer_id
GROUP BY cs.customer_state
ORDER BY total_revenue DESC
LIMIT 10;
  
--- question 5 : What percentage of total revenue comes from the top product categories?

 SELECT 
    ps.product_category_name AS product_category,
       ROUND(SUM(ois.price + ois.freight_value), 2) AS total_revenue,
    ROUND(
        SUM(ois.price + ois.freight_value) * 100.0 /
        (SELECT SUM(price + freight_value)
         FROM order_items_staging),
        2
    ) AS percentage_revenue
FROM order_items_staging ois
JOIN products_staging ps
    ON ois.product_id = ps.product_id
GROUP BY ps.product_category_name
ORDER BY total_revenue DESC
limit 5;

--- step 4: Customer Analysis

--- question 1: Which states have the highest number of customers?

select customer_state, count( distinct customer_unique_id) as total_customers
from customers_staging
group by customer_state
order by total_customers desc
limit 10;

--- question 2: How has customer acquisition changed over time?

WITH first_purchase AS (
    SELECT
        cs.customer_unique_id,
        MIN(os.order_purchase_timestamp) AS first_purchase_date
    FROM orders_staging os
    JOIN customers_staging cs
        ON os.customer_id = cs.customer_id
    GROUP BY cs.customer_unique_id
)
SELECT
    DATE_FORMAT(first_purchase_date, '%Y-%m') AS years_months,
    COUNT(customer_unique_id) AS new_customers
FROM first_purchase
GROUP BY DATE_FORMAT(first_purchase_date, '%Y-%m')
ORDER BY years_months ;

--- question 3: What is the average number of orders per customer?

select  round(count(distinct os.order_id)/count(distinct cs.customer_unique_id),2)as avg_orders_per_customer
from customers_staging cs
join orders_staging os on cs.customer_id = os.customer_id;


--- question 4: Which states generate the highest revenue per customer?

SELECT
    cs.customer_state,
    ROUND(
        SUM(ois.price + ois.freight_value) /
        COUNT(DISTINCT cs.customer_unique_id),
        2
    ) AS revenue_per_customer
FROM order_items_staging ois
JOIN orders_staging os
    ON ois.order_id = os.order_id
JOIN customers_staging cs
    ON os.customer_id = cs.customer_id
GROUP BY cs.customer_state
ORDER BY revenue_per_customer DESC;

--- question 5: Who are the most valuable customers?

SELECT
    cs.customer_unique_id,
    ROUND(SUM(ois.price + ois.freight_value), 2) AS total_revenue
FROM order_items_staging ois
JOIN orders_staging os
    ON ois.order_id = os.order_id
JOIN customers_staging cs
    ON os.customer_id = cs.customer_id
GROUP BY cs.customer_unique_id
ORDER BY total_revenue DESC
LIMIT 10;


--- step 5: product analysis

--- question 1:Which product categories sell the most units?

SELECT
    ps.product_category_name AS product_category,
    COUNT(ois.product_id) AS units_sold
FROM order_items_staging ois
JOIN products_staging ps
    ON ois.product_id = ps.product_id
GROUP BY ps.product_category_name
ORDER BY units_sold DESC;

--- Question 2: Which product categories generate the highest revenue?

SELECT
    ps.product_category_name AS product_category,
    ROUND(SUM(ois.price + ois.freight_value), 2) AS total_revenue
FROM order_items_staging ois
JOIN products_staging ps
    ON ois.product_id = ps.product_id
GROUP BY ps.product_category_name
ORDER BY total_revenue DESC;

--- question 3:Which product categories have the highest average selling price?
SELECT
    ps.product_category_name AS product_category,
    ROUND(AVG(ois.price), 2) AS avg_selling_price
FROM order_items_staging ois
JOIN products_staging ps
    ON ois.product_id = ps.product_id
GROUP BY ps.product_category_name
ORDER BY avg_selling_price DESC;

--- question 4: Which product categories receive the highest customer ratings?
SELECT
    ps.product_category_name AS product_category,
    ROUND(AVG(ors.review_score), 2) AS avg_review_score
FROM order_reviews_staging ors
JOIN orders_staging os
    ON ors.order_id = os.order_id
JOIN order_items_staging ois
    ON os.order_id = ois.order_id
JOIN products_staging ps
    ON ois.product_id = ps.product_id
GROUP BY ps.product_category_name
ORDER BY avg_review_score DESC;

--- question 5: Which product categories have the highest revenue per order?

SELECT
    ps.product_category_name AS product_category,
    ROUND(
        SUM(ois.price + ois.freight_value) /
        COUNT(DISTINCT ois.order_id),
        2
    ) AS revenue_per_order
FROM order_items_staging ois
JOIN products_staging ps
    ON ois.product_id = ps.product_id
GROUP BY ps.product_category_name
ORDER BY revenue_per_order DESC;


--- Step 6 → Review & Customer Satisfaction Analysis

--- question 1: Q1. What is the distribution of review scores?

SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM order_reviews_staging), 2) AS review_percentage
FROM order_reviews_staging
GROUP BY review_score
ORDER BY review_score;

--- question 2: Does delivery delay impact review scores?

SELECT
    ors.review_score,
    ROUND(AVG(DATEDIFF(os.order_delivered_customer_date, os.order_estimated_delivery_date)), 2) AS avg_delivery_delay_days,
    COUNT(*) AS total_reviews
FROM order_reviews_staging ors
JOIN orders_staging os
    ON ors.order_id = os.order_id
WHERE os.order_status = 'delivered'
  AND os.order_delivered_customer_date IS NOT NULL
GROUP BY ors.review_score
ORDER BY ors.review_score;

--- question 3: Product categories with highest/lowest review scores

SELECT
    ps.product_category_name AS product_category,
    ROUND(AVG(ors.review_score), 2) AS avg_review_score,
    COUNT(*) AS total_reviews
FROM order_reviews_staging ors
JOIN order_items_staging ois
    ON ors.order_id = ois.order_id
JOIN products_staging ps
    ON ois.product_id = ps.product_id
GROUP BY ps.product_category_name
HAVING COUNT(*) >= 50
ORDER BY avg_review_score DESC;

--- question 4: Positive, neutral, negative review percentage

select
case
when review_score >= 4 then 'Positive'
WHEN review_score = 3 THEN 'Neutral'
WHEN review_score  <= 2 THEN 'Negative'
end as review_sentiment,
count(*) as total_reviews,
round( count(*)  *100.0 / (select count(*) from order_reviews_staging),2) as review_percentage
from order_reviews_staging
group by review_sentiment
order by total_reviews desc;


--- step 7: Delivery & Logistics Analysis

--- question 1: What is the average delivery time?
SELECT
    ROUND(
        AVG(
            DATEDIFF(
                order_delivered_customer_date,
                order_purchase_timestamp
            )
        ),
        2
    ) AS avg_delivery_time_days
FROM orders_staging
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
  
  
  --- question 2: What percentage of orders were delivered on time?
  
  SELECT
    ROUND(
        COUNT(
            CASE
                WHEN order_delivered_customer_date <= order_estimated_delivery_date
                THEN 1
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS on_time_delivery_rate
FROM orders_staging
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
  
  --- question 3: Which states have the longest delivery times?
  
  SELECT
    cs.customer_state,
    ROUND(
        AVG(
            DATEDIFF(
                os.order_delivered_customer_date,
                os.order_purchase_timestamp
            )
        ),
        2
    ) AS avg_delivery_time_days
FROM orders_staging os
JOIN customers_staging cs
    ON os.customer_id = cs.customer_id
WHERE os.order_status = 'delivered'
  AND os.order_delivered_customer_date IS NOT NULL
GROUP BY cs.customer_state
ORDER BY avg_delivery_time_days DESC;

--- question 4: Does delivery delay impact review scores?

SELECT
    ors.review_score,
    ROUND(
        AVG(
            DATEDIFF(
                os.order_delivered_customer_date,
                os.order_estimated_delivery_date
            )
        ),
        2
    ) AS avg_delay_days,
    COUNT(*) AS total_reviews
FROM order_reviews_staging ors
JOIN orders_staging os
    ON ors.order_id = os.order_id
WHERE os.order_status = 'delivered'
  AND os.order_delivered_customer_date IS NOT NULL
GROUP BY ors.review_score
ORDER BY ors.review_score;
  

