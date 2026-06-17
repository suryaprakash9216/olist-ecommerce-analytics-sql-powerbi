create database olist_customers;

use olist_customers;

SELECT COUNT(*) 
FROM orders;

 ---- Meaning: checks if MySQL allows CSV import from your computer.
SHOW VARIABLES LIKE 'local_infile';

--- Meaning: turns on CSV file importing.
SET GLOBAL local_infile = 1;

--- Database → Manage Connections → Your Connection → Advanced
--- In Others, add:
--- OPT_LOCAL_INFILE=1
--- Click OK and reconnect.

---- Meaning: creates empty table for olist_order_items_dataset.csv.
CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);

LOAD DATA LOCAL INFILE 'C:/olist_project/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM order_items;

--- products 
CREATE TABLE products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

LOAD DATA LOCAL INFILE 'C:/olist_project/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM products;

--- Product Category Translation
CREATE TABLE product_category_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);

LOAD DATA LOCAL INFILE 'C:/olist_project/product_category_name_translation.csv'
INTO TABLE product_category_translation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM product_category_translation;

--- Sellers
CREATE TABLE sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);

LOAD DATA LOCAL INFILE 'C:/olist_project/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

 SELECT COUNT(*) FROM sellers;
 
 --- Order Payments
 CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

LOAD DATA LOCAL INFILE 'C:/olist_project/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

 SELECT COUNT(*) FROM order_payments;
 
 --- Order Reviews
 CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

LOAD DATA LOCAL INFILE 'C:/olist_project/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

 SELECT COUNT(*) FROM order_reviews;
 
 --- Geolocation
 CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(10,8),
    geolocation_lng DECIMAL(11,8),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
);

LOAD DATA LOCAL INFILE 'C:/olist_project/olist_geolocation_dataset.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
 
SELECT COUNT(*) FROM geolocation;

--- Verify all tables
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM sellers;
SELECT COUNT(*) FROM order_payments;
SELECT COUNT(*) FROM order_reviews;
SELECT COUNT(*) FROM product_category_translation;
SELECT COUNT(*) FROM geolocation;


