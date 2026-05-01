use techsperedata;

-- The date of the earliest and latest order.
SELECT 
  Min(purchase_ts) as earliest_order,
  Max(purchase_ts) as latest_order
FROM orders; 

-- The AOV for purchases made in the US in 2019.
SELECT
    Avg(usd_price) as usd_aov
FROM orders
WHERE currency = 'USD'
AND Extract(year from purchase_ts) = 2019;

-- Account creation dates for accounts made on desktop and mobile. 
SELECT 
  user_id as customer_id,
  loyalty_program as is_loyalty_customer,
  created_on as account_created_on
FROM customers
WHERE account_creation_method = 'desktop' or account_creation_method = 'mobile';

SELECT 
  user_id AS customer_id,
  created_on,
    CASE
    WHEN loyalty_program = 0 THEN 'Non_loyalty_member'
    ELSE 'Loyalty_member'
    END AS loyalty_program_status
FROM  customers
WHERE account_creation_method = 'mobile'
OR account_creation_method = 'desktop'
ORDER BY 2;

-- Unique products sold in AUD.
SELECT DISTINCT product_name
FROM orders
WHERE currency = 'AUD'
AND purchase_platform = 'mobile app'
ORDER BY 1 ASC;


-- First 10 countries in the North American region.
SELECT
  c.country_code,
  g.region
FROM customers c
  JOIN regions g 
    ON c.country_code = g.country_code
WHERE g.region = 'NA'
ORDER BY 1
LIMIT 10;

-- Total number of orders by shipping month, sorted recent to oldest.
SELECT
  Date_format(ship_ts, '%Y-%m-01') as ship_month,
  Count(order_id) as order_count
FROM order_status
GROUP BY 1
ORDER BY 1 DESC; 

-- AOV by year
SELECT
  round(Avg(usd_price), 2) as aov
FROM orders;

 -- Refund statuses
SELECT *,
  CASE
    WHEN refund_ts IS Null THEN 0
    ELSE 1
  END AS is_refund
FROM order_status
LIMIT 20; 

-- Product IDs and product names of Apple products.
  SELECT DISTINCT product_id,
  product_name
FROM orders
WHERE lower(product_name) LIKE '%apple%'
OR lower(product_name) LIKE '%macbook%';

-- Days to ship
SELECT *,
  datediff(ship_ts, purchase_ts) as days_to_ship
FROM order_status;

-- Order counts, sales, and AOV for Macbooks sold in North America for each quarter across all years
select 
  CONCAT(year(purchase_ts), '-Q', quarter(purchase_ts)) as purchase_quarter,
  count(orders.order_id) as order_count,
  round(sum(orders.usd_price), 2) as total_sales,
  round(avg(orders.usd_price), 2) as aov
from orders 
left join customers
  on orders.user_id = customers.user_id
left join regions
  on customers.country_code = regions.country_code
where region = 'NA'
and lower(product_name) like '%macbook%'
group by 1
order by 1 desc; 

-- Average quarterly order count and total sales for Macbooks sold in North America
with quarterly_metrics as (
  select 
    CONCAT(YEAR(orders.purchase_ts), '-Q', QUARTER(orders.purchase_ts)) AS purchase_quarter,
    count(distinct orders.order_id) as order_count,
    round(sum(orders.usd_price),2) as total_sales
  from orders
  left join customers
    on orders.user_id = customers.user_id
  left join regions
    on customers.country_code = regions.country_code
  where lower(orders.product_name) like '%macbook%'
    and region = 'NA'
  group by 1
  order by 1 desc)

select avg(order_count) as avg_quarter_orderes,
  avg(total_sales) as avg_quarter_sales
from quarterly_metrics;

-- Products purchased in 2022 on the website or products purchased on mobile in any year, which region has the average highest time to deliver? 
SELECT 
  IFNULL(region_cleaned, 'NA') AS region_cleaned,
  AVG(TIMESTAMPDIFF(day, order_status.purchase_ts, order_status.delivery_ts)) AS days_to_deliver
FROM orders
LEFT JOIN customers
  ON orders.user_id = customers.user_id 
LEFT JOIN order_status
  ON orders.order_id = order_status.order_id
LEFT JOIN regions
  ON customers.country_code = regions.country_code
WHERE  
  (orders.purchase_platform = 'website' AND YEAR(order_status.purchase_ts) = 2022)
  OR (orders.purchase_platform = 'mobile app')
GROUP BY 1
ORDER BY 2 DESC;
