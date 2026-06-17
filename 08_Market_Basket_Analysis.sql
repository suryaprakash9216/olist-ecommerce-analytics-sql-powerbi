use olist_customers;

--- Step 1: Find product/category pairs bought together

CREATE VIEW vw_market_basket AS
SELECT
    oi1.order_id,
    p1.product_category_name AS category_1,
    p2.product_category_name AS category_2
FROM order_items_staging oi1
JOIN order_items_staging oi2
    ON oi1.order_id = oi2.order_id
   AND oi1.product_id < oi2.product_id
JOIN products_staging p1
    ON oi1.product_id = p1.product_id
JOIN products_staging p2
    ON oi2.product_id = p2.product_id
WHERE p1.product_category_name IS NOT NULL
  AND p2.product_category_name IS NOT NULL;
  
  
--- Step 2: Most common category pairs

SELECT
    category_1,
    category_2,
    COUNT(*) AS times_bought_together
FROM vw_market_basket
GROUP BY category_1, category_2
ORDER BY times_bought_together DESC
LIMIT 20;


--- Step 3: Orders with multiple categories

SELECT
    order_id,
    COUNT(DISTINCT category_1) + COUNT(DISTINCT category_2) AS category_count
FROM vw_market_basket
GROUP BY order_id
ORDER BY category_count DESC;

--- Step 4: Total number of basket combinations

SELECT
    COUNT(*) AS total_basket_pairs
FROM vw_market_basket;