-- Check 1: row counts
SELECT 'sellers' AS tbl, COUNT(*) AS cnt FROM sellers
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments;

-- Check 2: duplicate line items (same order and item number)
SELECT COUNT(*) AS duplicate_line_items FROM (
  SELECT order_id, order_item_id
  FROM order_items
  GROUP BY order_id, order_item_id
  HAVING COUNT(*) > 1
) d;

-- Check 3: missing dates in orders
SELECT
  SUM(order_approved_at IS NULL) AS missing_approval_date,
  SUM(order_delivered_customer_date IS NULL) AS missing_delivery_date
FROM orders;

-- Check 4: orphan records (items with no matching order)
SELECT COUNT(*) AS orphan_items
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check 5: illogical dates (delivered before purchased)
SELECT COUNT(*) AS bad_dates
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- Check 6: payment total vs item total mismatch
WITH item_totals AS (
  SELECT order_id, SUM(price + freight_value) AS item_total
  FROM order_items GROUP BY order_id
),
pay_totals AS (
  SELECT order_id, SUM(payment_value) AS paid_total
  FROM order_payments GROUP BY order_id
)
SELECT COUNT(*) AS mismatched_orders
FROM item_totals i
JOIN pay_totals p ON i.order_id = p.order_id
WHERE ABS(i.item_total - p.paid_total) > 1;

USE p2p_project;

SELECT
  (SELECT COUNT(*) FROM (SELECT order_id, order_item_id FROM order_items GROUP BY order_id, order_item_id HAVING COUNT(*) > 1) d) AS duplicate_line_items,
  (SELECT SUM(order_approved_at IS NULL) FROM orders) AS missing_approval_date,
  (SELECT SUM(order_delivered_customer_date IS NULL) FROM orders) AS missing_delivery_date,
  (SELECT COUNT(*) FROM order_items oi LEFT JOIN orders o ON oi.order_id = o.order_id WHERE o.order_id IS NULL) AS orphan_items,
  (SELECT COUNT(*) FROM orders WHERE order_delivered_customer_date < order_purchase_timestamp) AS bad_dates;
  
  SELECT order_status,
       COUNT(*) AS total_orders,
       SUM(order_approved_at IS NULL) AS missing_approval,
       SUM(order_delivered_customer_date IS NULL) AS missing_delivery
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Check 7: delivered orders with missing timestamps (status inconsistencies)
SELECT order_id, order_status, order_approved_at, order_delivered_customer_date
FROM orders
WHERE order_status = 'delivered'
  AND (order_approved_at IS NULL OR order_delivered_customer_date IS NULL);
  
  USE p2p_project;

WITH item_totals AS (
  SELECT order_id, SUM(price + freight_value) AS item_total
  FROM order_items GROUP BY order_id
),
pay_totals AS (
  SELECT order_id, SUM(payment_value) AS paid_total
  FROM order_payments GROUP BY order_id
)
SELECT COUNT(*) AS mismatched_orders
FROM item_totals i
JOIN pay_totals p ON i.order_id = p.order_id
WHERE ABS(i.item_total - p.paid_total) > 1;

WITH item_totals AS (
  SELECT order_id, SUM(price + freight_value) AS item_total
  FROM order_items GROUP BY order_id
),
pay_totals AS (
  SELECT order_id, SUM(payment_value) AS paid_total, MAX(payment_installments) AS max_installments
  FROM order_payments GROUP BY order_id
)
SELECT i.order_id,
       ROUND(i.item_total, 2) AS item_total,
       ROUND(p.paid_total, 2) AS paid_total,
       ROUND(p.paid_total - i.item_total, 2) AS difference,
       p.max_installments
FROM item_totals i
JOIN pay_totals p ON i.order_id = p.order_id
WHERE ABS(i.item_total - p.paid_total) > 1
ORDER BY ABS(p.paid_total - i.item_total) DESC
LIMIT 10;

WITH item_totals AS (
  SELECT order_id, SUM(price + freight_value) AS item_total
  FROM order_items GROUP BY order_id
),
pay_totals AS (
  SELECT order_id, SUM(payment_value) AS paid_total, MAX(payment_installments) AS max_installments
  FROM order_payments GROUP BY order_id
)
SELECT
  COUNT(*) AS mismatched_orders,
  SUM(p.paid_total > i.item_total) AS overpaid,
  SUM(p.paid_total < i.item_total) AS underpaid,
  ROUND(AVG(p.max_installments), 1) AS avg_installments
FROM item_totals i
JOIN pay_totals p ON i.order_id = p.order_id
WHERE ABS(i.item_total - p.paid_total) > 1;

SELECT ROUND(AVG(max_inst), 1) AS avg_installments_all_orders
FROM (
  SELECT order_id, MAX(payment_installments) AS max_inst
  FROM order_payments
  GROUP BY order_id
) t;

USE p2p_project;

(SELECT 'Q1 Top supplier by spend' AS result_type,
        CAST(seller_id AS CHAR) AS label,
        ROUND(SUM(price), 2) AS value1,
        NULL AS value2
 FROM order_items
 GROUP BY seller_id
 ORDER BY SUM(price) DESC
 LIMIT 3)

UNION ALL

(SELECT 'Q2 Lowest on-time rate',
        CAST(oi.seller_id AS CHAR),
        COUNT(DISTINCT o.order_id),
        ROUND(100 * AVG(o.order_delivered_customer_date <= o.order_estimated_delivery_date), 1)
 FROM order_items oi
 JOIN orders o ON oi.order_id = o.order_id
 WHERE o.order_delivered_customer_date IS NOT NULL
 GROUP BY oi.seller_id
 HAVING COUNT(DISTINCT o.order_id) >= 30
 ORDER BY AVG(o.order_delivered_customer_date <= o.order_estimated_delivery_date) ASC
 LIMIT 3)

UNION ALL

(SELECT 'Q4 Highest spend month',
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m'),
        ROUND(SUM(oi.price), 2),
        NULL
 FROM orders o
 JOIN order_items oi ON o.order_id = oi.order_id
 GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
 ORDER BY SUM(oi.price) DESC
 LIMIT 1);
 
 USE p2p_project;

SELECT seller_id, ROUND(SUM(price), 2) AS total_spend
FROM order_items
GROUP BY seller_id
ORDER BY total_spend DESC
LIMIT 3;

SELECT ROUND(SUM(price), 2) AS total_spend_all_suppliers,
       COUNT(DISTINCT seller_id) AS total_suppliers
FROM order_items;

SELECT oi.seller_id,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(100 * AVG(o.order_delivered_customer_date <= o.order_estimated_delivery_date), 1) AS on_time_pct
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY oi.seller_id
HAVING orders >= 30
ORDER BY on_time_pct ASC
LIMIT 3;

SELECT ROUND(100 * AVG(order_delivered_customer_date <= order_estimated_delivery_date), 1) AS overall_on_time_pct
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
       ROUND(SUM(oi.price), 2) AS spend
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY month
ORDER BY spend DESC
LIMIT 1;