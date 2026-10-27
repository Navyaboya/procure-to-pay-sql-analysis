-- Query 1: top 10 suppliers by spend
SELECT seller_id, ROUND(SUM(price), 2) AS total_spend
FROM order_items
GROUP BY seller_id
ORDER BY total_spend DESC
LIMIT 10;

-- Query 2: on-time delivery rate per supplier (at least 30 orders)
SELECT oi.seller_id,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(100 * AVG(o.order_delivered_customer_date <= o.order_estimated_delivery_date), 1) AS on_time_pct
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY oi.seller_id
HAVING orders >= 30
ORDER BY on_time_pct ASC
LIMIT 10;

-- Query 3: average delivery delay per supplier, using a CTE
WITH delays AS (
  SELECT oi.seller_id,
         DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS delay_days
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.order_delivered_customer_date IS NOT NULL
)
SELECT seller_id, COUNT(*) AS items, ROUND(AVG(delay_days), 1) AS avg_delay_days
FROM delays
GROUP BY seller_id
HAVING items >= 30
ORDER BY avg_delay_days DESC
LIMIT 10;

-- Query 4: monthly spend trend
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
       ROUND(SUM(oi.price), 2) AS spend
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

-- Query 5: top supplier in each state (window function)
SELECT seller_state, seller_id, spend
FROM (
  SELECT s.seller_state, s.seller_id, ROUND(SUM(oi.price), 2) AS spend,
         RANK() OVER (PARTITION BY s.seller_state ORDER BY SUM(oi.price) DESC) AS rnk
  FROM order_items oi
  JOIN sellers s ON oi.seller_id = s.seller_id
  GROUP BY s.seller_state, s.seller_id
) t
WHERE rnk = 1
ORDER BY spend DESC;