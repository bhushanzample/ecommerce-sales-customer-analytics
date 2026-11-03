
DROP SCHEMA IF EXISTS ecommerce CASCADE;
CREATE SCHEMA ecommerce;
SET search_path TO ecommerce;
SET datestyle = 'DMY';

CREATE TABLE customer_master (
    customer_id VARCHAR(30) PRIMARY KEY,
    customer_name VARCHAR(150),
    customer_age INT,
    gender VARCHAR(30),
    customer_segment VARCHAR(50),
    customer_city VARCHAR(100),
    customer_state VARCHAR(100),
    customer_country VARCHAR(100),
    region VARCHAR(50),
    customer_postal_code INT,
    customer_acquisition_cost NUMERIC(12,2)
);

CREATE TABLE product_catalog (
    product_id VARCHAR(30) PRIMARY KEY,
    product_name VARCHAR(200),
    product_category VARCHAR(100),
    product_subcategory VARCHAR(100),
    brand VARCHAR(100),
    supplier VARCHAR(150),
    unit_price NUMERIC(12,2),
    product_cost NUMERIC(12,2),
    product_rating NUMERIC(4,2)
);

CREATE TABLE sales_orders (
    order_id VARCHAR(40) PRIMARY KEY,
    order_date DATE,
    order_time TIME,
    order_status VARCHAR(30),
    sales_channel VARCHAR(50),
    customer_id VARCHAR(30),
    customer_name VARCHAR(150),
    customer_age INT,
    gender VARCHAR(30),
    customer_segment VARCHAR(50),
    customer_type VARCHAR(30),
    customer_city VARCHAR(100),
    customer_state VARCHAR(100),
    customer_country VARCHAR(100),
    region VARCHAR(50),
    customer_postal_code INT,
    payment_method VARCHAR(50),
    payment_status VARCHAR(30),
    currency VARCHAR(10),
    shipping_method VARCHAR(50),
    warehouse VARCHAR(50),
    delivery_days NUMERIC(10,2),
    estimated_delivery_days NUMERIC(10,2),
    delivery_status VARCHAR(30),
    return_status VARCHAR(30),
    return_reason VARCHAR(150),
    customer_rating NUMERIC(4,2),
    review_sentiment VARCHAR(30),
    customer_review TEXT,
    marketing_channel VARCHAR(100),
    campaign_name VARCHAR(150),
    coupon_code VARCHAR(100),
    loyalty_points_earned INT,
    loyalty_points_redeemed INT,
    quantity INT,
    gross_sales NUMERIC(14,2),
    discount_amount NUMERIC(14,2),
    tax_amount NUMERIC(14,2),
    shipping_cost NUMERIC(14,2),
    net_sales NUMERIC(14,2),
    product_cost NUMERIC(14,2),
    profit NUMERIC(14,2),
    profit_margin_percentage NUMERIC(8,2),
    customer_lifetime_value NUMERIC(14,2),
    is_repeat_customer BOOLEAN,
    CONSTRAINT fk_sales_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer_master(customer_id)
);

CREATE TABLE order_items (
    order_item_id BIGSERIAL PRIMARY KEY,
    order_id VARCHAR(40),
    product_id VARCHAR(30),
    quantity INT,
    unit_price NUMERIC(12,2),
    discount_percentage NUMERIC(8,2),
    discount_amount NUMERIC(14,2),
    gross_sales NUMERIC(14,2),
    tax_amount NUMERIC(14,2),
    shipping_cost NUMERIC(14,2),
    net_sales NUMERIC(14,2),
    product_cost NUMERIC(14,2),
    profit NUMERIC(14,2),
    CONSTRAINT fk_items_order
        FOREIGN KEY (order_id) REFERENCES sales_orders(order_id),
    CONSTRAINT fk_items_product
        FOREIGN KEY (product_id) REFERENCES product_catalog(product_id)
);

CREATE INDEX idx_sales_customer ON sales_orders(customer_id);
CREATE INDEX idx_sales_date ON sales_orders(order_date);
CREATE INDEX idx_sales_status ON sales_orders(order_status);
CREATE INDEX idx_sales_region ON sales_orders(region);
CREATE INDEX idx_sales_channel ON sales_orders(sales_channel);
CREATE INDEX idx_items_order ON order_items(order_id);
CREATE INDEX idx_items_product ON order_items(product_id);

-- 02_IMPORT_DATA.sql
SET search_path TO ecommerce;
SET datestyle = 'DMY';

-- CHANGE ONLY THE FOLDER PATH IF NEEDED.
-- Example: D:/ecommerce_project/


COPY customer_master
FROM 'D:/data/customer_master.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

COPY product_catalog
FROM 'D:/data/product_catalog.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

COPY ecommerce_sales_customer_analytics_150k
FROM 'D:/data/ecommerce_sales_customer_analytics_150k.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

COPY order_items
FROM 'D:/data/order_items.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

DROP TABLE IF EXISTS order_items;

CREATE TABLE order_items (
    order_id TEXT,
    product_id TEXT,
    quantity INTEGER,
    unit_price NUMERIC(12,2),
    discount_percentage NUMERIC(10,6),
    discount_amount NUMERIC(12,2),
    gross_sales NUMERIC(12,2),
    tax_amount NUMERIC(12,2),
    shipping_cost NUMERIC(12,2),
    net_sales NUMERIC(12,2),
    product_cost NUMERIC(12,2),
    profit NUMERIC(12,2)
);

SET search_path TO ecommerce;

SELECT 'customer_master' AS table_name, COUNT(*) AS rows FROM customer_master
UNION ALL
SELECT 'product_catalog', COUNT(*) FROM product_catalog
UNION ALL
SELECT 'sales_orders', COUNT(*) FROM sales_orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;

SELECT COUNT(DISTINCT customer_id) AS sales_customers
FROM sales_orders;

SELECT COUNT(*) AS missing_customer_links
FROM sales_orders s
LEFT JOIN customer_master c ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS missing_product_links
FROM order_items oi
LEFT JOIN product_catalog p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT MIN(order_date) AS first_order_date,
       MAX(order_date) AS last_order_date,
       SUM(net_sales) AS total_net_sales,
       SUM(profit) AS total_profit
FROM sales_orders
WHERE order_status <> 'Cancelled';

-- 04_15_ANALYSIS.sql
SET search_path TO ecommerce;

-- 01 Overall KPI
SELECT COUNT(DISTINCT order_id) AS total_orders,
       COUNT(DISTINCT customer_id) AS total_customers,
       ROUND(SUM(net_sales),2) AS total_revenue,
       ROUND(SUM(profit),2) AS total_profit,
       ROUND(AVG(net_sales),2) AS average_order_value,
       ROUND(SUM(profit)/NULLIF(SUM(net_sales),0)*100,2) AS profit_margin
FROM sales_orders
WHERE order_status <> 'Cancelled';

-- 02 Monthly trend
SELECT DATE_TRUNC('month',order_date)::DATE AS month,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(net_sales),2) AS revenue,
       ROUND(SUM(profit),2) AS profit
FROM sales_orders
WHERE order_status <> 'Cancelled'
GROUP BY 1 ORDER BY 1;

-- 03 Customer segment
SELECT customer_segment,
       COUNT(DISTINCT customer_id) AS customers,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(net_sales),2) AS revenue,
       ROUND(SUM(profit),2) AS profit,
       ROUND(AVG(net_sales),2) AS avg_order_value
FROM sales_orders
WHERE order_status <> 'Cancelled'
GROUP BY customer_segment
ORDER BY revenue DESC;

-- 04 Region
SELECT region,
       COUNT(DISTINCT order_id) AS orders,
       COUNT(DISTINCT customer_id) AS customers,
       ROUND(SUM(net_sales),2) AS revenue,
       ROUND(SUM(profit),2) AS profit,
       ROUND(SUM(profit)/NULLIF(SUM(net_sales),0)*100,2) AS margin
FROM sales_orders
WHERE order_status <> 'Cancelled'
GROUP BY region ORDER BY revenue DESC;

-- 05 Sales channel
SELECT sales_channel,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(net_sales),2) AS revenue,
       ROUND(SUM(profit),2) AS profit,
       ROUND(AVG(net_sales),2) AS avg_order_value
FROM sales_orders
WHERE order_status <> 'Cancelled'
GROUP BY sales_channel ORDER BY revenue DESC;

-- 06 Category / subcategory
SELECT p.product_category,
       p.product_subcategory,
       SUM(oi.quantity) AS units_sold,
       ROUND(SUM(oi.net_sales),2) AS revenue,
       ROUND(SUM(oi.profit),2) AS profit,
       ROUND(SUM(oi.profit)/NULLIF(SUM(oi.net_sales),0)*100,2) AS margin
FROM order_items oi
JOIN product_catalog p ON oi.product_id=p.product_id
GROUP BY p.product_category,p.product_subcategory
ORDER BY revenue DESC;

-- 07 Top 10 products
SELECT p.product_id,p.product_name,p.product_category,p.brand,
       SUM(oi.quantity) AS units_sold,
       ROUND(SUM(oi.net_sales),2) AS revenue,
       ROUND(SUM(oi.profit),2) AS profit
FROM order_items oi
JOIN product_catalog p ON oi.product_id=p.product_id
GROUP BY p.product_id,p.product_name,p.product_category,p.brand
ORDER BY revenue DESC
LIMIT 10;


-- 08 Customer profitability
SELECT customer_id,
       MAX(customer_name) AS customer_name,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(net_sales),2) AS revenue,
       ROUND(SUM(profit),2) AS profit,
       ROUND(AVG(net_sales),2) AS avg_order_value
FROM sales_orders
WHERE order_status <> 'Cancelled'
GROUP BY customer_id
ORDER BY profit DESC
LIMIT 20;