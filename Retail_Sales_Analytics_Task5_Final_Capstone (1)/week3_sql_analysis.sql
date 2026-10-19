-- Retail Sales Analytics — Week 3 SQL Analysis (SQLite)
-- Open retail_sales.db; the main table is sales. Execute queries individually.

-- 1. Core KPIs
SELECT ROUND(SUM(sales),2) total_sales, ROUND(SUM(profit),2) total_profit,
 COUNT(DISTINCT order_id) total_orders, COUNT(DISTINCT customer_id) total_customers,
 SUM(quantity) total_quantity, ROUND(100.0*SUM(profit)/NULLIF(SUM(sales),0),2) profit_margin_pct,
 ROUND(SUM(sales)/COUNT(DISTINCT order_id),2) average_order_value FROM sales;

-- 2. Monthly sales/profit trend
SELECT strftime('%Y-%m',order_date) year_month, ROUND(SUM(sales),2) sales,
 ROUND(SUM(profit),2) profit, COUNT(DISTINCT order_id) orders
FROM sales GROUP BY strftime('%Y-%m',order_date) ORDER BY year_month;

-- 3. Regional performance
SELECT region,ROUND(SUM(sales),2) sales,ROUND(SUM(profit),2) profit,
 COUNT(DISTINCT order_id) orders,ROUND(100.0*SUM(profit)/SUM(sales),2) profit_margin_pct
FROM sales GROUP BY region ORDER BY sales DESC;

-- 4. Category performance
SELECT category,ROUND(SUM(sales),2) sales,ROUND(SUM(profit),2) profit,SUM(quantity) quantity
FROM sales GROUP BY category ORDER BY sales DESC;

-- 5. Top 10 products by sales
SELECT product_id,product_name,category,sub_category,ROUND(SUM(sales),2) sales,ROUND(SUM(profit),2) profit
FROM sales GROUP BY product_id,product_name,category,sub_category ORDER BY sales DESC LIMIT 10;

-- 6. Top 10 products by profit
SELECT product_id,product_name,category,sub_category,ROUND(SUM(profit),2) profit,ROUND(SUM(sales),2) sales
FROM sales GROUP BY product_id,product_name,category,sub_category ORDER BY profit DESC LIMIT 10;

-- 7. Bottom 10 products by profit
SELECT product_id,product_name,category,sub_category,ROUND(SUM(profit),2) profit,ROUND(SUM(sales),2) sales
FROM sales GROUP BY product_id,product_name,category,sub_category ORDER BY profit ASC LIMIT 10;

-- 8. Customer sales and order analysis
SELECT customer_id,customer_name,segment,ROUND(SUM(sales),2) sales,ROUND(SUM(profit),2) profit,
 COUNT(DISTINCT order_id) orders,ROUND(SUM(sales)/COUNT(DISTINCT order_id),2) avg_order_value
FROM sales GROUP BY customer_id,customer_name,segment ORDER BY sales DESC LIMIT 20;

-- 9. Discount bands and profitability
SELECT CASE WHEN discount=0 THEN '0% (none)' WHEN discount<=0.10 THEN '>0–10%'
 WHEN discount<=0.20 THEN '>10–20%' WHEN discount<=0.30 THEN '>20–30%' ELSE '>30%' END discount_band,
 COUNT(*) transaction_lines,ROUND(AVG(discount)*100,2) avg_discount_pct,
 ROUND(SUM(sales),2) sales,ROUND(SUM(profit),2) profit,
 ROUND(100.0*SUM(profit)/NULLIF(SUM(sales),0),2) profit_margin_pct
FROM sales GROUP BY discount_band ORDER BY AVG(discount);

-- 10. Loss-making sub-categories
SELECT sub_category,ROUND(SUM(sales),2) sales,ROUND(SUM(profit),2) profit,SUM(quantity) quantity
FROM sales GROUP BY sub_category HAVING SUM(profit)<0 ORDER BY profit;

-- 11. Repeat-purchase customers
SELECT customer_id,customer_name,COUNT(DISTINCT order_id) orders,ROUND(SUM(sales),2) sales
FROM sales GROUP BY customer_id,customer_name HAVING COUNT(DISTINCT order_id)>1
ORDER BY orders DESC,sales DESC;

-- 12. Average shipping duration by shipping mode
SELECT ship_mode,ROUND(AVG(julianday(ship_date)-julianday(order_date)),2) avg_shipping_days,
 COUNT(DISTINCT order_id) orders FROM sales GROUP BY ship_mode ORDER BY avg_shipping_days;

-- 13. Transparent customer segmentation using ranked quartile thresholds
WITH cs AS (SELECT customer_id,customer_name,SUM(sales) total_sales,SUM(profit) total_profit
 FROM sales GROUP BY customer_id,customer_name),
 ranked AS (SELECT *,NTILE(4) OVER(ORDER BY total_sales DESC) sales_quartile FROM cs)
SELECT *,CASE WHEN sales_quartile=1 THEN 'High-value'
 WHEN sales_quartile IN (2,3) THEN 'Medium-value' ELSE 'Low-value' END customer_segment
FROM ranked ORDER BY total_sales DESC;
