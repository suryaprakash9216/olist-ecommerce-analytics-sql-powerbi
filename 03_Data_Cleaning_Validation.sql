use olist_customers;

--- Data_Cleaning_Validation.sql

SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM sellers;
SELECT COUNT(*) FROM order_payments;
SELECT COUNT(*) FROM order_reviews;
SELECT COUNT(*) FROM product_category_translation;
SELECT COUNT(*) FROM geolocation;

--- Remove Duplicates
--- we need to create tempary table 


--- Create staging table
CREATE TABLE customers_staging AS
SELECT * FROM customers;
--- Check row count
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM customers_staging;
--- Check duplicates
select customer_id, count(*) as duplicate_count
from customers_staging
group by customer_id
having count(*) >1;
--- Standardise the data
SELECT DISTINCT customer_city
FROM customers_staging
ORDER BY customer_city
LIMIT 20;

SELECT DISTINCT customer_state
FROM customers_staging
ORDER BY customer_state;

SELECT * FROM customers_staging;

--- Check Null Values
select * from customers_staging
where customer_zip_code_prefix is null 
or customer_zip_code_prefix = ' ';

--- or ---

SELECT
SUM(customer_id IS NULL) AS customer_id_nulls,
SUM(customer_unique_id IS NULL) AS customer_unique_id_nulls,
SUM(customer_zip_code_prefix IS NULL) AS zip_nulls,
SUM(customer_city IS NULL) AS city_nulls,
SUM(customer_state IS NULL) AS state_nulls
FROM customers_staging;

--- Validate Data Types ---

DESCRIBE customers_staging;

--- next table cleaning ---
CREATE TABLE orders_staging AS
SELECT * FROM orders;

SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM orders_staging;

SELECT order_id, COUNT(*) AS duplicate_count
FROM orders_staging
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT DISTINCT order_status
FROM orders_staging
ORDER BY order_status; 

SELECT *
FROM orders_staging
WHERE order_id IS NULL
   OR customer_id IS NULL
   OR order_status IS NULL;
   
DESCRIBE orders_staging;

select * from orders_staging;

--- next table cleaning ---
CREATE TABLE order_items_staging AS
SELECT * FROM order_items;

SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM order_items_staging;

SELECT order_id,
       order_item_id,
       COUNT(*) AS duplicate_count
FROM order_items_staging
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

SELECT DISTINCT seller_id
FROM order_items_staging
LIMIT 10;

SELECT *
FROM order_items_staging
WHERE order_id IS NULL
   OR order_item_id IS NULL
   OR product_id IS NULL
   OR seller_id IS NULL;
   
   DESCRIBE order_items_staging;
   
   --- next table cleaning ---
CREATE TABLE products_staging AS
SELECT * FROM products;

SELECT product_id,
       COUNT(*) AS duplicate_count
FROM products_staging
GROUP BY product_id
HAVING COUNT(*) > 1;
   
SELECT DISTINCT product_category_name
FROM products_staging
ORDER BY product_category_name;

SELECT *
FROM products_staging
WHERE product_id IS NULL
   OR product_category_name IS NULL;

DESCRIBE products_staging;

--- all together ---
-- ==========================================
-- SELLERS
-- ==========================================


CREATE TABLE sellers_staging AS
SELECT *
FROM sellers;

SELECT seller_id,
       COUNT(*) AS duplicate_count
FROM sellers_staging
GROUP BY seller_id
HAVING COUNT(*) > 1;

SELECT *
FROM sellers_staging
WHERE seller_id IS NULL;

DESCRIBE sellers_staging;


-- ==========================================
-- PRODUCT CATEGORY TRANSLATION
-- ==========================================


CREATE TABLE product_category_translation_staging AS
SELECT *
FROM product_category_translation;

SELECT product_category_name,
       COUNT(*) AS duplicate_count
FROM product_category_translation_staging
GROUP BY product_category_name
HAVING COUNT(*) > 1;

SELECT *
FROM product_category_translation_staging
WHERE product_category_name IS NULL
   OR product_category_name_english IS NULL;

DESCRIBE product_category_translation_staging;


-- ==========================================
-- ORDER PAYMENTS
-- ==========================================

 

CREATE TABLE order_payments_staging AS
SELECT *
FROM order_payments;

SELECT order_id,
       payment_sequential,
       COUNT(*) AS duplicate_count
FROM order_payments_staging
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;

SELECT *
FROM order_payments_staging
WHERE order_id IS NULL
   OR payment_type IS NULL
   OR payment_value IS NULL;

DESCRIBE order_payments_staging;


-- ==========================================
-- ORDER REVIEWS
-- ==========================================
 

CREATE TABLE order_reviews_staging AS
SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    CAST(review_creation_date AS CHAR) AS review_creation_date,
    CAST(review_answer_timestamp AS CHAR) AS review_answer_timestamp
FROM order_reviews;

 SELECT COUNT(*)
FROM order_reviews_staging;

SELECT review_id,
       COUNT(*) AS duplicate_count
FROM order_reviews_staging
GROUP BY review_id
HAVING COUNT(*) > 1;

 SELECT review_id,
       order_id,
       COUNT(*) AS duplicate_count
FROM order_reviews_staging
GROUP BY review_id, order_id
HAVING COUNT(*) > 1;

SELECT review_id,
       order_id,
       COUNT(*) AS duplicate_count
FROM order_reviews_staging
GROUP BY review_id, order_id
HAVING COUNT(*) > 1;

SELECT *
FROM order_reviews_staging
WHERE review_id IS NULL
   OR order_id IS NULL
   OR review_score IS NULL;

DESCRIBE order_reviews_staging;


-- ==========================================
-- GEOLOCATION
-- ==========================================

CREATE TABLE geolocation_staging AS
SELECT *
FROM geolocation;

SELECT geolocation_zip_code_prefix,
       geolocation_lat,
       geolocation_lng,
       COUNT(*) AS duplicate_count
FROM geolocation_staging
GROUP BY geolocation_zip_code_prefix,
         geolocation_lat,
         geolocation_lng
HAVING COUNT(*) > 1;

SELECT geolocation_zip_code_prefix,
       geolocation_lat,
       geolocation_lng,
       geolocation_city,
       geolocation_state,
       COUNT(*) AS duplicate_count
FROM geolocation_staging
GROUP BY geolocation_zip_code_prefix,
         geolocation_lat,
         geolocation_lng,
         geolocation_city,
         geolocation_state
HAVING COUNT(*) > 1;

SELECT *
FROM geolocation_staging
WHERE geolocation_zip_code_prefix IS NULL
   OR geolocation_city IS NULL
   OR geolocation_state IS NULL;

DESCRIBE geolocation_staging;