/*
===============================================================================
OLIST E-COMMERCE SALES & CUSTOMER ANALYTICS
PostgreSQL Portfolio Project
===============================================================================

Project scope
-------------
Database setup, data-quality assessment, cleaning, validation, exploratory
analysis, analytical-view construction, and business analysis.

Objective
---------
Prepare the Olist e-commerce dataset for reliable SQL analysis and downstream
Tableau reporting while preserving the original source tables.

Analytical principles
---------------------
- Preserve raw source tables and perform transformations on working copies.
- Validate completeness, consistency, conformity, uniqueness, and integrity.
- Avoid unsupported imputation; retain genuine unknown values as NULL.
- Protect metric accuracy by controlling table grain before joins/aggregations.
- Use dedicated clean and analytical views for downstream analysis.
- Use delivered orders for realized sales/revenue KPIs unless stated otherwise.
- Document anomalies instead of silently overwriting uncertain values.
===============================================================================
*/




-- ============================================================
-- 1. PRODUCT CATEGORY TRANSLATION
-- ============================================================

CREATE TABLE product_category_name_translation (
    product_category_name           VARCHAR(50) PRIMARY KEY,
    product_category_name_english   VARCHAR(50) NOT NULL
);

-- ============================================================
-- 2. SELLERS
-- ============================================================

CREATE TABLE olist_sellers (
    seller_id               VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix  INTEGER NOT NULL,
    seller_city             VARCHAR(50) NOT NULL,
    seller_state            VARCHAR(2) NOT NULL
);

-- ============================================================
-- 3. CUSTOMERS
-- ============================================================

CREATE TABLE olist_customers (
    customer_id               VARCHAR(32) PRIMARY KEY,
    customer_unique_id        VARCHAR(32) NOT NULL,
    customer_zip_code_prefix  INTEGER NOT NULL,
    customer_city             VARCHAR(50) NOT NULL,
    customer_state            VARCHAR(2) NOT NULL
);

-- ============================================================
-- 4. PRODUCTS
-- ============================================================

CREATE TABLE olist_products (
    product_id                    VARCHAR(32) PRIMARY KEY,
    product_category_name         VARCHAR(50),
    product_name_lenght           INTEGER,
    product_description_lenght    INTEGER,
    product_photos_qty            INTEGER,
    product_weight_g              NUMERIC,
    product_length_cm             NUMERIC,
    product_height_cm             NUMERIC,
    product_width_cm              NUMERIC
);

-- ============================================================
-- 5. ORDERS
-- ============================================================

CREATE TABLE olist_orders (
    order_id                       VARCHAR(32) PRIMARY KEY,
    customer_id                    VARCHAR(32) NOT NULL,
    order_status                   VARCHAR(20) NOT NULL,

    order_purchase_timestamp       TIMESTAMP NOT NULL,
    order_approved_at              TIMESTAMP,
    order_delivered_carrier_date   TIMESTAMP,
    order_delivered_customer_date  TIMESTAMP,
    order_estimated_delivery_date  TIMESTAMP NOT NULL,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES olist_customers(customer_id)
);


-- ============================================================
-- 6. ORDER ITEMS
-- ============================================================

CREATE TABLE olist_order_items (
    order_id             VARCHAR(32) NOT NULL,
    order_item_id        INTEGER NOT NULL,
    product_id           VARCHAR(32) NOT NULL,
    seller_id            VARCHAR(32) NOT NULL,
    shipping_limit_date  TIMESTAMP NOT NULL,
    price                NUMERIC(12,2) NOT NULL,
    freight_value        NUMERIC(12,2) NOT NULL,

    CONSTRAINT pk_order_items
        PRIMARY KEY (order_id, order_item_id),

    CONSTRAINT fk_items_order
        FOREIGN KEY (order_id)
        REFERENCES olist_orders(order_id),

    CONSTRAINT fk_items_product
        FOREIGN KEY (product_id)
        REFERENCES olist_products(product_id),

    CONSTRAINT fk_items_seller
        FOREIGN KEY (seller_id)
        REFERENCES olist_sellers(seller_id)
);


-- ============================================================
-- 7. ORDER PAYMENTS
-- ============================================================

CREATE TABLE olist_order_payments (
    order_id              VARCHAR(32) NOT NULL,
    payment_sequential    INTEGER NOT NULL,
    payment_type          VARCHAR(20) NOT NULL,
    payment_installments  INTEGER NOT NULL,
    payment_value         NUMERIC(12,2) NOT NULL,

    CONSTRAINT pk_order_payments
        PRIMARY KEY (order_id, payment_sequential),

    CONSTRAINT fk_payment_order
        FOREIGN KEY (order_id)
        REFERENCES olist_orders(order_id)
);

-- ============================================================
-- 8. ORDER REVIEWS
-- ============================================================

CREATE TABLE olist_order_reviews (
    review_id                VARCHAR(32) NOT NULL,
    order_id                 VARCHAR(32) NOT NULL,
    review_score             INTEGER NOT NULL,
    review_comment_title     VARCHAR(50),
    review_comment_message   VARCHAR(300),
    review_creation_date     TIMESTAMP NOT NULL,
    review_answer_timestamp  TIMESTAMP NOT NULL,

    CONSTRAINT pk_order_reviews
        PRIMARY KEY (review_id, order_id),

    CONSTRAINT fk_review_order
        FOREIGN KEY (order_id)
        REFERENCES olist_orders(order_id)
);

-- ============================================================
-- 9. GEOLOCATION
-- ============================================================

CREATE TABLE olist_geolocation (
    geolocation_zip_code_prefix  INTEGER NOT NULL,
    geolocation_lat              NUMERIC(12,8) NOT NULL,
    geolocation_lng              NUMERIC(12,8) NOT NULL,
    geolocation_city             VARCHAR(50) NOT NULL,
    geolocation_state            VARCHAR(2) NOT NULL
);

select *
from public.olist_customers

select *
from public.olist_geolocation

select *
from public.olist_order_items

select *
from public.olist_order_payments

select *
from public.olist_order_reviews

select *
from public.olist_orders

select *
from public.olist_products

select *
from public.olist_sellers

select *
from public.product_category_name_translation

/*
1. Row-count check
2. Primary-key / duplicate check
3. NULL audit
4. Data-type check
5. Invalid-value check
6. Foreign-key / orphan check
7. Create working-copy tables
8. Clean the copies
9. Create clean views
10. Start EDA and business questions*/

-- 1. Row-Count Validation
SELECT COUNT(*) FROM olist_customers
union all 
SELECT COUNT(*) FROM olist_geolocation
union all
SELECT COUNT(*) FROM olist_order_items
union all
SELECT COUNT(*) FROM olist_order_payments
union all
SELECT COUNT(*) FROM olist_order_reviews
union all
SELECT COUNT(*) FROM olist_orders
union all
SELECT COUNT(*) FROM olist_products
union all
SELECT COUNT(*) FROM olist_sellers
union all
SELECT COUNT(*) FROM product_category_name_translation;

-- 2. Primary-Key and Duplicate Validation
SELECT customer_id, COUNT(*)
FROM olist_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*)
FROM olist_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT product_id, COUNT(*)
FROM olist_products
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT seller_id, COUNT(*)
FROM olist_sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

SELECT
    order_id,
    order_item_id,
    COUNT(*)
FROM olist_order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

SELECT
    order_id,
    payment_sequential,
    COUNT(*)
FROM olist_order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;

-- 3. Referential Integrity and NULL Audit
-- Check for orders without a matching customer
SELECT o.*
FROM olist_orders AS o
LEFT JOIN olist_customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Check for order items without a matching order
SELECT oi.*
FROM olist_order_items AS oi
LEFT JOIN olist_orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check for order items without a matching product
SELECT oi.*
FROM olist_order_items AS oi
LEFT JOIN olist_products AS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Check for order items without a matching seller
SELECT oi.*
FROM olist_order_items AS oi
LEFT JOIN olist_sellers AS s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

SELECT
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS missing_purchase_date,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS missing_delivery_date,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS missing_estimated_date
FROM olist_orders;

SELECT
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS missing_category
FROM olist_products;



SELECT 'olist_customers' AS table_name, COUNT(*) AS total_rows
FROM olist_customers

UNION ALL

SELECT 'olist_geolocation', COUNT(*)
FROM olist_geolocation

UNION ALL

SELECT 'olist_order_items', COUNT(*)
FROM olist_order_items

UNION ALL

SELECT 'olist_order_payments', COUNT(*)
FROM olist_order_payments

UNION ALL

SELECT 'olist_order_reviews', COUNT(*)
FROM olist_order_reviews

UNION ALL

SELECT 'olist_orders', COUNT(*)
FROM olist_orders

UNION ALL

SELECT 'olist_products', COUNT(*)
FROM olist_products

UNION ALL

SELECT 'olist_sellers', COUNT(*)
FROM olist_sellers

UNION ALL

SELECT 'product_category_name_translation', COUNT(*)
FROM product_category_name_translation;

-- ============================================================
-- WORKING COPY TABLES
-- Purpose: Preserve the raw source tables and perform all cleaning
--          operations on isolated working copies.
-- ============================================================

CREATE TABLE public.olist_customers_copy AS
SELECT * FROM public.olist_customers;

CREATE TABLE public.olist_geolocation_copy AS
SELECT * FROM public.olist_geolocation;

CREATE TABLE public.olist_order_items_copy AS
SELECT * FROM public.olist_order_items;

CREATE TABLE public.olist_order_payments_copy AS
SELECT * FROM public.olist_order_payments;


CREATE TABLE public.olist_order_reviews_copy AS
SELECT * FROM public.olist_order_reviews;

CREATE TABLE public.olist_orders_copy AS
SELECT * FROM public.olist_orders;

CREATE TABLE public.olist_products_copy AS
SELECT * FROM public.olist_products;

CREATE TABLE public.olist_sellers_copy AS
SELECT * FROM public.olist_sellers;

CREATE TABLE public.product_category_name_translation_copy AS
SELECT * FROM public.product_category_name_translation;

select *
from public.olist_customers_copy

select *
from public.olist_geolocation_copy

select *
from public.olist_order_items_copy

select *
from public.olist_order_payments_copy

select *
from public.olist_order_reviews_copy

select *
from public.olist_orders_copy

select *
from public.olist_products_copy

select *
from public.olist_sellers_copy

select *
from public.product_category_name_translation_copy

SELECT 'olist_customers' AS table_name, COUNT(*) AS total_rows
FROM olist_customers_copy;

UNION ALL

SELECT 'olist_geolocation', COUNT(*)
FROM olist_geolocation_copy;

UNION ALL

SELECT 'olist_order_items', COUNT(*)
FROM olist_order_items_copy;

UNION ALL

SELECT 'olist_order_payments', COUNT(*)
FROM olist_order_payments_copy;

UNION ALL

SELECT 'olist_order_reviews', COUNT(*)
FROM olist_order_reviews_copy;

UNION ALL

SELECT 'olist_orders', COUNT(*)
FROM olist_orders_copy;

UNION ALL

SELECT 'olist_products', COUNT(*)
FROM olist_products_copy;

UNION ALL

SELECT 'olist_sellers', COUNT(*)
FROM olist_sellers_copy;

UNION ALL

SELECT 'product_category_name_translation', COUNT(*)
FROM product_category_name_translation_copy;


-- Validation: Working copies were created successfully and row counts
-- match the corresponding raw source tables.

-- ============================================================
-- DATA CLEANING: OLIST_CUSTOMERS
-- ============================================================
select *
from public.olist_customers_copy
-- 1. Completeness Check
select 
	count(*) as total_rows,
	count(*)-count(customer_id) as missing_customer_id,
	count(*)-count(customer_unique_id) as missing_unique_id,
	count(*)-count(customer_zip_code_prefix) as missing_zip_code,
	count(*)-count(customer_city) as missing_city,
	count(*)-count(customer_state) as missing_state
from public.olist_customers_copy
-- Result: No missing values were identified in the evaluated columns.

-- 2. Consistency and Standardization Checks
select  
	customer_city,
	count(*)
from public.olist_customers_copy
group by customer_city

select  
	customer_zip_code_prefix,
	count(*)
from public.olist_customers_copy
group by customer_zip_code_prefix -- Review ZIP-code distribution

select  
	customer_state,
	count(*)
from public.olist_customers_copy
group by customer_state -- Review state-code distribution and casing


UPDATE olist_customers_copy
SET customer_city = INITCAP(TRIM(customer_city));

-- Check for blank or empty string values
SELECT
    COUNT(*) FILTER (
        WHERE TRIM(customer_id) = ''
    ) AS empty_customer_id,

    COUNT(*) FILTER (
        WHERE TRIM(customer_unique_id) = ''
    ) AS empty_unique_id,

    COUNT(*) FILTER (
        WHERE TRIM(customer_city) = ''
    ) AS empty_city,

    COUNT(*) FILTER (
        WHERE TRIM(customer_state) = ''
    ) AS empty_state

FROM olist_customers_copy;

-- 3. Conformity / Key Uniqueness Check
SELECT
    customer_id,
    COUNT(*) AS total_rows
FROM olist_customers_copy
GROUP BY customer_id
HAVING COUNT(*) > 1; -- Expected result: 0 rows; customer_id should be unique

-- 4. Duplicate Check
SELECT
    customer_id,
	customer_unique_id,
    COUNT(*) AS total_rows
FROM olist_customers_copy
GROUP BY customer_id,customer_unique_id
HAVING COUNT(*) > 1; -- Expected result: 0 duplicate key combinations


-- Create the cleaned customer view
CREATE OR REPLACE VIEW olist_customers_clean AS
SELECT *
FROM olist_customers_copy;

select *
from olist_customers_clean


-- ============================================================
-- DATA CLEANING: OLIST_GEOLOCATION
-- ============================================================
select *
from public.olist_geolocation_copy
-- 1. Completeness Check
select 
	count(*) as total_rows,
	count(*)-count(geolocation_zip_code_prefix) as missing_zip_code,
	count(*)-count(geolocation_lat) as missing_geolocation_lat,
	count(*)-count(geolocation_lng) as missing_geolocation_lng,
	count(*)-count(geolocation_city) as missing_geolocation_city,
	count(*)-count(geolocation_state) as missing_geolocation_state
from public.olist_geolocation_copy
-- Result: No missing values were identified in the evaluated columns.

-- 2. Consistency and Standardization Checks
select  
	geolocation_city,
	count(*)
from public.olist_geolocation_copy
group by geolocation_city

select  
	geolocation_zip_code_prefix,
	count(*)
from public.olist_geolocation_copy
group by geolocation_zip_code_prefix -- Review ZIP-code distribution

select  
	geolocation_state,
	count(*)
from public.olist_geolocation_copy
group by geolocation_state -- Review state-code distribution and casing


UPDATE olist_geolocation_copy
SET geolocation_city = INITCAP(TRIM(geolocation_city));

-- Check for blank or empty string values
SELECT
    COUNT(*) FILTER (
        WHERE TRIM(geolocation_state) = ''
    ) AS empty_state

FROM olist_geolocation_copy;


-- 3. Duplicate Check
-- Exact duplicate check across all geolocation attributes

SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    COUNT(*) AS total_rows
FROM olist_geolocation_copy
GROUP BY
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
HAVING COUNT(*) > 1
ORDER BY total_rows DESC;

CREATE TABLE olist_geolocation_dedup AS
SELECT DISTINCT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
FROM olist_geolocation_copy;

SELECT
    (SELECT COUNT(*)
     FROM olist_geolocation_copy) AS original_rows,

    (SELECT COUNT(*)
     FROM olist_geolocation_dedup) AS deduplicated_rows,

    (SELECT COUNT(*)
     FROM olist_geolocation_copy)
    -
    (SELECT COUNT(*)
     FROM olist_geolocation_dedup) AS removed_duplicates;

SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    COUNT(*) AS total_rows
FROM olist_geolocation_dedup
GROUP BY
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
HAVING COUNT(*) > 1;
-- Create the cleaned geolocation view
CREATE OR REPLACE VIEW olist_geolocation_clean AS
SELECT *
FROM olist_geolocation_dedup;

select *
from olist_geolocation_clean

-- ============================================================
-- DATA CLEANING: OLIST_ORDER_ITEMS
-- ============================================================
select *
from public.olist_order_items_copy

-- 1. Completeness Check
select 
	count(*) as total_rows,
	count(*)-count(order_id) as missingorder_id,
	count(*)-count(order_item_id) as missingorder_item_id,
	count(*)-count(seller_id) as missing_seller_id,
	count(*)-count(shipping_limit_date) as missingshipping_limit_date,
	count(*)-count(price) as missing_price,
	count(*)-count(freight_value) as missing_freight_value
from public.olist_order_items_copy -- Result: No missing values identified

SELECT
    order_id,
    order_item_id,
    seller_id
FROM olist_order_items_copy
WHERE
    UPPER(TRIM(order_id)) NOT IN ('N/A', 'NA', 'NULL', '')
    AND order_id IS NOT NULL

    AND order_item_id IS NOT NULL

    AND UPPER(TRIM(seller_id)) NOT IN ('N/A', 'NA', 'NULL', '')
    AND seller_id IS NOT NULL; -- Valid-value coverage check

-- 2. Consistency and Validity Checks
select distinct
	price,
	count(*)
from olist_order_items_copy
where price<0
group by price

select 
	order_item_id,
	count(*)
from olist_order_items_copy
where order_item_id<0
group by order_item_id

SELECT
    shipping_limit_date,
    COUNT(*)
FROM olist_order_items_copy
WHERE shipping_limit_date > TIMESTAMP '2026-01-01'
GROUP BY shipping_limit_date;

-- 3. Duplicate Check
-- Validate uniqueness at the order-item grain
select
	order_id,
	seller_id,
	order_item_id,
	count(*) as totalrows
from olist_order_items_copy
group by 
	order_id,
	seller_id,
	order_item_id
having count(*)>1
order by totalrows desc

-- Standardize identifier strings by trimming whitespace
update olist_order_items_copy
set 
	order_id=Trim(order_id),
	product_id=trim(product_id),
	seller_id=trim(seller_id)

CREATE OR REPLACE VIEW olist_order_items_clean AS
SELECT *
FROM olist_order_items_copy;


-- ============================================================
-- DATA CLEANING: OLIST_ORDER_PAYMENTS
-- ============================================================
select *
from public.olist_order_payments_copy

-- 1. Completeness Check
select 
	count(*) as total_rows,
	count(*)-count(order_id) as missing_order_id,
	count(*)-count(payment_sequential) as missing_payment_sequential,
	count(*)-count(payment_type) as missing_payment_type,
	count(*)-count(payment_installments) as missing_payment_installments,
	count(*)-count(payment_value) as missing_payment_value
from public.olist_order_payments_copy -- Result: No missing values identified

SELECT
    order_id,
    payment_type
FROM olist_order_payments_copy
WHERE
    UPPER(TRIM(order_id)) NOT IN ('N/A', 'NA', 'NULL', '')
    AND order_id IS NOT NULL

    AND UPPER(TRIM(payment_type)) NOT IN ('N/A', 'NA', 'NULL', '')
    AND payment_type IS NOT NULL; -- Valid-value coverage check

-- 2. Consistency and Validity Checks
select 
	payment_type,
	count(*)
from olist_order_payments_copy
group by payment_type

UPDATE olist_order_payments_copy
SET payment_type = INITCAP(TRIM(payment_type));

select
	payment_sequential,
	payment_installments,
	payment_value
from olist_order_payments_copy
where payment_sequential<0
or payment_installments<0
or payment_value<0

-- 3. Duplicate Check
SELECT
    order_id,
	payment_sequential,
	payment_type,
    COUNT(*)
FROM olist_order_payments_copy
GROUP BY 
	order_id,
	payment_sequential,
	payment_type
HAVING COUNT(*) > 1;

-- Standardize identifier strings by trimming whitespace
update olist_order_payments_copy
set order_id=Trim(order_id)


CREATE OR REPLACE VIEW olist_order_payments_clean AS
SELECT *
FROM olist_order_payments_copy;

-- ============================================================
-- DATA CLEANING: OLIST_ORDER_REVIEWS
-- ============================================================
select *
from public.olist_order_reviews_copy

-- 1. Completeness Check
select 
	count(*) as total_rows,
	count(*)-count(review_id) as missing_review_id,
	count(*)-count(order_id) as missing_order_id,
	count(*)-count(review_score) as missing_review_score,
	count(*)-count(review_comment_title) as missing_review_comment_title,
	count(*)-count(review_comment_message) as missing_review_comment_message,
	count(*)-count(review_creation_date) as missing_review_creation_date,
	count(*)-count(review_answer_timestamp) as missing_review_answer_timestamp
from public.olist_order_reviews_copy -- Core identifiers and review fields were evaluated for completeness

-- 2. Consistency and Validity Checks
-- Standardize identifier and comment fields by trimming whitespace.
update olist_order_reviews_copy
set review_id=trim(review_id),
	order_id=trim(order_id),
	review_comment_title=trim(review_comment_title),
	review_comment_message=trim(review_comment_message);

-- Validate review creation and response timestamp formats

select 
	review_creation_date,
	count(*)
from olist_order_reviews_copy
group by review_creation_date

SELECT
    COUNT(*) AS rows_with_real_time
FROM olist_order_reviews_copy
WHERE review_creation_date::time <> TIME '00:00:00'; -- Non-midnight times exist; retain TIMESTAMP data type

select 
	review_answer_timestamp,
	count(*)
from olist_order_reviews_copy
group by review_answer_timestamp; -- Timestamp values retained at full precision

Select 
	review_score
from olist_order_reviews_copy
WHERE review_score NOT BETWEEN 1 AND 5; -- Expected result: 0 invalid review scores

-- Duplicate Check
select 
	review_id,
	order_id,
	count(*)
from olist_order_reviews_copy
group by 
	review_id,
	order_id
having Count(*)>1 -- Expected result: 0 duplicate review/order combinations


CREATE OR REPLACE VIEW olist_order_reviews_clean AS
SELECT
    review_id,
    order_id,
    review_score,

    COALESCE(review_comment_title, 'No Comment') AS review_comment_title,

    COALESCE(review_comment_message, 'No Comment') AS review_comment_message,

    review_creation_date,
    review_answer_timestamp
FROM olist_order_reviews_copy;

select *
from olist_order_reviews_clean


-- ============================================================
-- DATA CLEANING: OLIST_ORDERS
-- ============================================================
select *
from public.olist_orders_copy

-- 1. Completeness Check
select 
	count(*) as total_rows,
	count(*)-count(order_id) as missing_order_id,
	count(*)-count(customer_id) as missing_customer_id,
	count(*)-count(order_status) as missing_order_status,
	count(*)-count(order_purchase_timestamp) as missing_order_purchase_timestamp,
	count(*)-count(order_approved_at) as missing_order_approved_at,
	count(*)-count(order_delivered_carrier_date) as missing_order_delivered_carrier_date,
	count(*)-count(order_delivered_customer_date) as missing_order_delivered_customer_date,
	count(*)-count(order_estimated_delivery_date) as missing_order_estimated_delivery_date
from public.olist_orders_copy

SELECT
    order_status,

    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_approved_at IS NULL
    ) AS missing_approved_at,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NULL
    ) AS missing_carrier_date,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_customer_delivery_date

FROM olist_orders_copy
GROUP BY order_status
ORDER BY total_orders DESC; -- Missing operational timestamps are reviewed by order status

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM olist_orders_copy
WHERE LOWER(order_status) = 'delivered'
  AND (
        order_approved_at IS NULL
        OR order_delivered_carrier_date IS NULL
        OR order_delivered_customer_date IS NULL
      ); -- Missing delivered-order timestamps are retained as NULL; no unsupported imputation is applied


-- 2. Consistency and Validity Checks
-- Standardize identifier and comment fields by trimming whitespace.
update olist_orders_copy
set order_id=trim(order_id),
	customer_id=trim(customer_id),
	order_status=initcap(trim(order_status));

select
	order_status,
	count(*)
from olist_orders_copy
group by order_status -- Review valid order-status categories and distribution

SELECT *
FROM olist_orders_copy
WHERE
       order_approved_at < order_purchase_timestamp
    OR order_delivered_carrier_date < order_purchase_timestamp
    OR order_delivered_customer_date < order_purchase_timestamp
    OR order_delivered_customer_date < order_delivered_carrier_date;

	SELECT
    COUNT(*) FILTER (
        WHERE order_approved_at < order_purchase_timestamp
    ) AS approved_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date < order_purchase_timestamp
    ) AS carrier_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date < order_approved_at
    ) AS carrier_before_approval,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date < order_purchase_timestamp
    ) AS delivered_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date < order_delivered_carrier_date
    ) AS delivered_before_carrier

FROM olist_orders_copy; -- Review chronological consistency across order timestamps

SELECT *
FROM olist_orders_copy
WHERE LOWER(order_status) = 'delivered'
  AND (
       order_approved_at IS NULL
       OR order_delivered_carrier_date IS NULL
       OR order_delivered_customer_date IS NULL
  ); -- Investigate delivered orders with incomplete operational timestamps

  SELECT
    MIN(order_purchase_timestamp) AS min_purchase,
    MAX(order_purchase_timestamp) AS max_purchase,
    MIN(order_delivered_customer_date) AS min_delivery,
    MAX(order_delivered_customer_date) AS max_delivery
FROM olist_orders_copy;

-- Duplicate Check
select
	order_id,
	customer_id,
	count(*)
from olist_orders_copy
group by 
	order_id,
	customer_id
having count(*)>1 -- Expected result: 0 duplicate key combinations


CREATE OR REPLACE VIEW olist_orders_clean AS
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    CASE
        WHEN LOWER(order_status) = 'delivered'
             AND order_approved_at IS NULL
        THEN 1 ELSE 0
    END AS missing_approval_flag,

    CASE
        WHEN LOWER(order_status) = 'delivered'
             AND order_delivered_carrier_date IS NULL
        THEN 1 ELSE 0
    END AS missing_carrier_date_flag,

    CASE
        WHEN LOWER(order_status) = 'delivered'
             AND order_delivered_customer_date IS NULL
        THEN 1 ELSE 0
    END AS missing_delivery_date_flag,

    CASE
        WHEN order_delivered_carrier_date < order_purchase_timestamp
        THEN 1 ELSE 0
    END AS carrier_before_purchase_flag,

    CASE
        WHEN order_delivered_carrier_date < order_approved_at
        THEN 1 ELSE 0
    END AS carrier_before_approval_flag,

    CASE
        WHEN order_delivered_customer_date < order_delivered_carrier_date
        THEN 1 ELSE 0
    END AS delivery_before_carrier_flag,

    CASE
        WHEN order_delivered_customer_date IS NULL
        THEN 'Not Delivered'
        WHEN order_delivered_customer_date > order_estimated_delivery_date
        THEN 'Late'
        ELSE 'On Time / Early'
    END AS delivery_performance

FROM olist_orders_copy;


select *
from olist_orders_clean

SELECT
    COUNT(*) AS total_rows,
    SUM(missing_approval_flag) AS missing_approval,
    SUM(missing_carrier_date_flag) AS missing_carrier,
    SUM(missing_delivery_date_flag) AS missing_delivery,
    SUM(carrier_before_purchase_flag) AS carrier_before_purchase,
    SUM(carrier_before_approval_flag) AS carrier_before_approval,
    SUM(delivery_before_carrier_flag) AS delivery_before_carrier
FROM olist_orders_clean;

-- ============================================================
-- DATA CLEANING: OLIST_PRODUCTS
-- ============================================================
select *
from public.olist_products

-- 1. Completeness Check
-- Objective: Verify that all required product attributes are populated.
select 
	count(*) as total_rows,
	count(*)-count(product_id) as missing_product_id,
	count(*)-count(product_category_name) as missing_product_category_name,
	count(*)-count(product_name_lenght) as missing_product_name_lenght,
	count(*)-count(product_description_lenght) as missing_product_description_lenght,
	count(*)-count(product_photos_qty) as missing_product_photos_qty,
	count(*)-count(product_weight_g) as missing_product_weight_g,
	count(*)-count(product_length_cm) as missing_product_length_cm,
	count(*)-count(product_height_cm) as missing_product_height_cm,
	count(*)-count(product_width_cm) as missing_product_width_cm
FROM public.olist_products_copy;

SELECT COUNT(*)
FROM olist_products_copy
WHERE product_category_name IS NULL
  AND product_name_lenght IS NULL
  AND product_description_lenght IS NULL
  AND product_photos_qty IS NULL; -- Confirms the same 610 rows share the missing metadata pattern


-- 2. Consistency and Validity Checks
update olist_products_copy
set product_id=trim(product_id),
	product_category_name=trim(product_category_name)

SELECT
    COUNT(*) FILTER (WHERE product_name_lenght < 0) AS negative_name_length,
    COUNT(*) FILTER (WHERE product_description_lenght < 0) AS negative_description_length,
    COUNT(*) FILTER (WHERE product_photos_qty < 0) AS negative_photos_qty,
    COUNT(*) FILTER (WHERE product_weight_g < 0) AS negative_weight,
    COUNT(*) FILTER (WHERE product_length_cm < 0) AS negative_length,
    COUNT(*) FILTER (WHERE product_height_cm < 0) AS negative_height,
    COUNT(*) FILTER (WHERE product_width_cm < 0) AS negative_width,

    COUNT(*) FILTER (WHERE product_weight_g = 0) AS zero_weight,
    COUNT(*) FILTER (WHERE product_length_cm = 0) AS zero_length,
    COUNT(*) FILTER (WHERE product_height_cm = 0) AS zero_height,
    COUNT(*) FILTER (WHERE product_width_cm = 0) AS zero_width

FROM olist_products_copy;


SELECT
    product_id,
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM olist_products_copy
WHERE product_weight_g = 0;

UPDATE olist_products_copy
SET product_weight_g = NULL
WHERE product_weight_g = 0;



-- 3. Duplicate Check
select *
from public.olist_products

select 
	product_id,
	product_category_name,
	count(*)
from olist_products_copy
group by 
	product_id,
	product_category_name
having count(*)>1 -- Expected result: 0 duplicate product/category combinations


CREATE OR REPLACE VIEW olist_products_clean AS
SELECT
    product_id,

    -- Reporting-friendly product category label
    COALESCE(
        INITCAP(REPLACE(TRIM(product_category_name), '_', ' ')),
        'Unknown'
    ) AS product_category_name,

    -- Correct source-field spelling through view aliases
    product_name_lenght AS product_name_length,
    product_description_lenght AS product_description_length,

    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,

    -- Flag products with incomplete descriptive metadata
    CASE
        WHEN product_category_name IS NULL
          OR product_name_lenght IS NULL
          OR product_description_lenght IS NULL
          OR product_photos_qty IS NULL
        THEN 1
        ELSE 0
    END AS missing_metadata_flag,

    -- Flag products with incomplete physical-dimension data
    CASE
        WHEN product_weight_g IS NULL
          OR product_length_cm IS NULL
          OR product_height_cm IS NULL
          OR product_width_cm IS NULL
        THEN 1
        ELSE 0
    END AS missing_dimensions_flag

FROM olist_products_copy;

select *
from olist_products_clean

-- ============================================================
-- DATA CLEANING: OLIST_SELLERS
-- ============================================================
select *
from public.olist_sellers_copy

-- 1. Completeness Check
select 
	count(*) as total_rows,
	count(*)-count(seller_id) as missing_seller_id,
	count(*)-count(seller_zip_code_prefix) as missing_zip_code,
	count(*)-count(seller_city) as missing_seller_city,
	count(*)-count(seller_state) as missing_seller_state
from public.olist_sellers_copy -- Result: No missing values identified

-- 2. Consistency and Validity Checks
update public.olist_sellers_copy
set seller_id = TRIM(seller_id),
    seller_city = INITCAP(TRIM(seller_city)),
    seller_state = TRIM(seller_state);

select 
	seller_city,
	count(*)
from public.olist_sellers_copy
group by seller_city -- Review seller distribution by city


select 
	seller_state,
	count(*)
from public.olist_sellers_copy
group by seller_state -- Review seller distribution by state

select
	seller_zip_code_prefix
from public.olist_sellers_copy
WHERE seller_zip_code_prefix < 0
   OR seller_zip_code_prefix > 99999; -- Expected result: 0 invalid ZIP-code prefixes

-- 3. Duplicate Check
select
	seller_id,
	seller_city,
	count(*)
from public.olist_sellers_copy
group by 
	seller_id,
	seller_city
having count(*)>1 -- Expected result: 0 duplicate key combinations

-- Create the cleaned seller view
CREATE OR REPLACE VIEW olist_sellers_clean AS
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_copy;

SELECT *
FROM olist_sellers_clean;

-- ============================================================
-- DATA CLEANING: PRODUCT_CATEGORY_NAME_TRANSLATION
-- ============================================================
select *
from public.product_category_name_translation_copy

-- 1. Completeness Check
select
	count(*),
	count(*)-count(product_category_name) as missing_category_name,
	count(*)-count(product_category_name_english) as missing_product_category_name_english
from public.product_category_name_translation_copy -- Result: No missing values identified

-- 2. Consistency and Validity Checks
update public.product_category_name_translation_copy
set product_category_name = TRIM(product_category_name),
    product_category_name_english = TRIM(product_category_name_english);

-- Create the cleaned category translation view
create or replace view public.product_category_name_translation_clean as
select
	product_category_name,
	product_category_name_english
from product_category_name_translation_copy

select *
from product_category_name_translation_clean


-- ============================================================
-- EXPLORATORY DATA ANALYSIS (EDA)
-- ============================================================

-- ============================================================
-- EDA 01: DATASET OVERVIEW
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM olist_orders_clean) AS total_orders,

    (SELECT COUNT(DISTINCT customer_unique_id)
     FROM olist_customers_clean) AS unique_customers,

    (SELECT COUNT(*) FROM olist_products_clean) AS total_products,

    (SELECT COUNT(*) FROM olist_sellers_clean) AS total_sellers;


-- ============================================================
-- EDA 02: DATE RANGE
-- ============================================================

SELECT
    MIN(order_purchase_timestamp) AS first_order_date,
    MAX(order_purchase_timestamp) AS last_order_date
FROM olist_orders_clean;

-- ============================================================
-- EDA 03: ORDER STATUS DISTRIBUTION
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_orders
FROM olist_orders_clean
GROUP BY order_status
ORDER BY total_orders DESC;

-- ============================================================
-- EDA 04: PAYMENT METHOD DISTRIBUTION
-- ============================================================

SELECT
    payment_type,
    COUNT(*) AS total_payments,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_payments
FROM olist_order_payments_clean
GROUP BY payment_type
ORDER BY total_payments DESC;

-- ============================================================
-- EDA 05: REVIEW SCORE DISTRIBUTION
-- ============================================================

SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_reviews
FROM olist_order_reviews_clean
GROUP BY review_score
ORDER BY review_score;

-- ============================================================
-- EDA 06: PRODUCT CATEGORY DISTRIBUTION
-- ============================================================

SELECT
    product_category_name,
    COUNT(*) AS total_products
FROM olist_products_clean
GROUP BY product_category_name
ORDER BY total_products DESC;

-- ============================================================
-- EDA 07: CUSTOMERS BY STATE
-- ============================================================

SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM olist_customers_clean
GROUP BY customer_state
ORDER BY unique_customers DESC;

-- ============================================================
-- EDA 08: SELLERS BY STATE
-- ============================================================

SELECT
    seller_state,
    COUNT(DISTINCT seller_id) AS total_sellers
FROM olist_sellers_clean
GROUP BY seller_state
ORDER BY total_sellers DESC;


-- ============================================================
-- EDA 09: PRODUCT PRICE DISTRIBUTION
-- ============================================================

SELECT
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    ROUND(AVG(price), 2) AS avg_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) AS median_price
FROM olist_order_items_clean;

-- ============================================================
-- EDA 10: FREIGHT VALUE DISTRIBUTION
-- ============================================================

SELECT
    MIN(freight_value) AS min_freight,
    MAX(freight_value) AS max_freight,
    ROUND(AVG(freight_value), 2) AS avg_freight,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY freight_value) AS median_freight
FROM olist_order_items_clean;

-- ============================================================
-- EDA 11: MONTHLY ORDER VOLUME
-- ============================================================

SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS order_month,
    COUNT(*) AS total_orders
FROM olist_orders_clean
GROUP BY order_month
ORDER BY order_month;

-- ============================================================
-- EDA 12: DELIVERY PERFORMANCE DISTRIBUTION
-- ============================================================

SELECT
    delivery_performance,
    COUNT(*) AS total_orders
FROM olist_orders_clean
GROUP BY delivery_performance
ORDER BY total_orders DESC;

-- ============================================================
-- EDA 13: PRODUCT DATA QUALITY SUMMARY
-- ============================================================

SELECT
    SUM(missing_metadata_flag) AS products_missing_metadata,
    SUM(missing_dimensions_flag) AS products_missing_dimensions
FROM olist_products_clean;

-- ============================================================
-- EDA 14: CUSTOMER ORDER FREQUENCY
-- ============================================================

SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM olist_customers_clean AS c
JOIN olist_orders_clean AS o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
ORDER BY total_orders DESC;


WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM olist_customers_clean AS c
    JOIN olist_orders_clean AS o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)

SELECT
    total_orders,
    COUNT(*) AS customers
FROM customer_orders
GROUP BY total_orders
ORDER BY total_orders;


-- ============================================================
-- ANALYTICAL VIEW 01: ORDER ITEMS AGGREGATED BY ORDER
-- Grain: 1 row per order_id
-- ============================================================

CREATE OR REPLACE VIEW vw_order_items_agg AS
SELECT
    order_id,

    COUNT(*) AS total_items,

    COUNT(DISTINCT product_id) AS unique_products,

    COUNT(DISTINCT seller_id) AS unique_sellers,

    SUM(price) AS total_product_value,

    SUM(freight_value) AS total_freight_value,

    SUM(price + freight_value) AS total_order_item_value,

    AVG(price) AS avg_item_price,

    MAX(price) AS max_item_price,

    MIN(price) AS min_item_price

FROM olist_order_items_clean
GROUP BY order_id;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM vw_order_items_agg;


-- ============================================================
-- ANALYTICAL VIEW 02: PAYMENTS AGGREGATED BY ORDER
-- Grain: 1 row per order_id
-- ============================================================

CREATE OR REPLACE VIEW vw_payments_agg AS
SELECT
    order_id,

    COUNT(*) AS payment_records,

    COUNT(DISTINCT payment_type) AS payment_methods_used,

    SUM(payment_value) AS total_payment_value,

    MAX(payment_installments) AS max_installments

FROM olist_order_payments_clean
GROUP BY order_id;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM vw_payments_agg;


-- ============================================================
-- ANALYTICAL VIEW 03: REVIEWS AGGREGATED BY ORDER
-- Grain: 1 row per order_id
-- ============================================================

CREATE OR REPLACE VIEW vw_reviews_agg AS
SELECT
    order_id,

    COUNT(*) AS review_records,

    ROUND(AVG(review_score), 2) AS avg_review_score,

    MIN(review_score) AS min_review_score,

    MAX(review_score) AS max_review_score

FROM olist_order_reviews_clean
GROUP BY order_id;



SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM vw_reviews_agg;



-- ============================================================
-- ANALYTICAL VIEW 04: MASTER ORDER ANALYSIS
-- Grain: 1 row per order_id
-- ============================================================

CREATE OR REPLACE VIEW vw_order_analysis AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    o.delivery_performance,

    oi.total_items,
    oi.unique_products,
    oi.unique_sellers,
    oi.total_product_value,
    oi.total_freight_value,
    oi.total_order_item_value,
    oi.avg_item_price,

    p.payment_records,
    p.payment_methods_used,
    p.total_payment_value,
    p.max_installments,

    r.review_records,
    r.avg_review_score,
    r.min_review_score,
    r.max_review_score

FROM olist_orders_clean AS o

LEFT JOIN olist_customers_clean AS c
    ON o.customer_id = c.customer_id

LEFT JOIN vw_order_items_agg AS oi
    ON o.order_id = oi.order_id

LEFT JOIN vw_payments_agg AS p
    ON o.order_id = p.order_id

LEFT JOIN vw_reviews_agg AS r
    ON o.order_id = r.order_id;


	SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM vw_order_analysis;


SELECT
    (SELECT COUNT(*) FROM olist_orders_clean) AS clean_orders,
    (SELECT COUNT(*) FROM vw_order_analysis) AS analytical_orders;




-- ============================================================
-- ANALYTICAL VIEW 05: PRODUCT / CATEGORY ANALYSIS
-- Grain: 1 row per order item
-- ============================================================

CREATE OR REPLACE VIEW vw_product_analysis AS
SELECT
    oi.order_id,
    oi.order_item_id,

    oi.product_id,
    p.product_category_name,

    oi.seller_id,
    s.seller_city,
    s.seller_state,

    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    o.order_status,
    o.order_purchase_timestamp,
    o.delivery_performance,

    oi.price,
    oi.freight_value,
    (oi.price + oi.freight_value) AS total_item_value,

    r.avg_review_score

FROM olist_order_items_clean AS oi

LEFT JOIN olist_products_clean AS p
    ON oi.product_id = p.product_id

LEFT JOIN olist_sellers_clean AS s
    ON oi.seller_id = s.seller_id

LEFT JOIN olist_orders_clean AS o
    ON oi.order_id = o.order_id

LEFT JOIN olist_customers_clean AS c
    ON o.customer_id = c.customer_id

LEFT JOIN vw_reviews_agg AS r
    ON oi.order_id = r.order_id;



SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS missing_order_id,
    COUNT(*) FILTER (
        WHERE product_id IS NULL
    ) AS missing_product_id,
    COUNT(*) FILTER (
        WHERE seller_id IS NULL
    ) AS missing_seller_id
FROM vw_product_analysis;



SELECT
    (SELECT COUNT(*) FROM olist_order_items_clean) AS order_item_rows,
    (SELECT COUNT(*) FROM vw_product_analysis) AS product_analysis_rows;


-- ============================================================
-- BUSINESS QUESTION 01
-- What is the total number of orders?
-- ============================================================

SELECT
    COUNT(order_id) AS total_orders
FROM public.vw_order_analysis;



-- ============================================================
-- BUSINESS QUESTION 02
-- What is the total revenue generated?
-- ============================================================
SELECT
    ROUND(SUM(total_product_value), 2) AS total_revenue
FROM public.vw_order_analysis
WHERE order_status = 'Delivered';

-- ============================================================
-- BUSINESS QUESTION 03
-- What is the average order value (AOV)?
-- ============================================================
SELECT
    ROUND(AVG(total_product_value), 2) AS avg_order_value
FROM public.vw_order_analysis
WHERE order_status = 'Delivered';

-- ============================================================
-- BUSINESS QUESTION 04
-- How many unique customers placed orders?
-- ============================================================
SELECT
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM public.vw_order_analysis;

-- ============================================================
-- BUSINESS QUESTION 05
-- What percentage of orders were successfully delivered?
-- ============================================================
SELECT
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE order_status = 'Delivered')
        / COUNT(*)
    , 2) AS pct_successful_orders
FROM public.vw_order_analysis;


-- ============================================================
-- BUSINESS QUESTION 06
-- How has revenue changed over time by month?
-- Use delivered orders only.
-- ============================================================

SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
    SUM(total_product_value) AS monthly_revenue
FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)::date
ORDER BY order_month;


-- ============================================================
-- BUSINESS QUESTION 07
-- Which month generated the highest revenue?
-- ============================================================

SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
    SUM(total_product_value) AS monthly_revenue
FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)::date
ORDER BY monthly_revenue DESC
LIMIT 1;


-- ============================================================
-- BUSINESS QUESTION 08
-- What is the month-over-month revenue growth rate?
-- ============================================================

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
        SUM(total_product_value) AS monthly_revenue
    FROM public.vw_order_analysis
    WHERE order_status = 'Delivered'
    GROUP BY DATE_TRUNC('month', order_purchase_timestamp)::date
)

SELECT
    order_month,
    monthly_revenue,

    LAG(monthly_revenue) OVER (
        ORDER BY order_month
    ) AS previous_month_revenue,

    ROUND(
        100.0 *
        (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY order_month))
        /
        NULLIF(
            LAG(monthly_revenue) OVER (ORDER BY order_month),
            0
        ),
        2
    ) AS mom_growth_pct

FROM monthly_revenue
ORDER BY order_month;

-- ============================================================
-- BUSINESS QUESTION 09
-- How did order volume change by month?
-- Use delivered orders only.
-- ============================================================
WITH volume_change AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
        COUNT(order_id) AS total_orders_per_month
    FROM vw_order_analysis
    WHERE order_status = 'Delivered'
    GROUP BY DATE_TRUNC('month', order_purchase_timestamp)::date
)

SELECT
    order_month,
    total_orders_per_month,
    ROUND(
        100.0 *
        (
            total_orders_per_month
            - LAG(total_orders_per_month) OVER (ORDER BY order_month)
        )
        /
        NULLIF(
            LAG(total_orders_per_month) OVER (ORDER BY order_month),
            0
        ),
        2
    ) AS mom_volume_pct
FROM volume_change
ORDER BY order_month;

-- ============================================================
-- BUSINESS QUESTION 10
-- Which month had the highest Average Order Value?
-- ============================================================


SELECT
	DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
    ROUND(AVG(total_product_value), 2) AS avg_order_value
FROM public.vw_order_analysis
 WHERE order_status = 'Delivered'
 GROUP BY DATE_TRUNC('month', order_purchase_timestamp)::date
order by avg_order_value desc
Limit 1;

-- ============================================================
-- BUSINESS QUESTION 11
-- Which product categories generated the highest revenue?
-- Use delivered orders only.
-- ============================================================

SELECT
    product_category_name,
    ROUND(SUM(price), 2) AS total_revenue
FROM public.vw_product_analysis
WHERE order_status = 'Delivered'
GROUP BY product_category_name
ORDER BY total_revenue DESC;



-- ============================================================
-- BUSINESS QUESTION 12
-- Which product categories sold the most items?
-- ============================================================
SELECT
    product_category_name,
    COUNT(*) AS total_items_sold
FROM public.vw_product_analysis
WHERE order_status = 'Delivered'
GROUP BY product_category_name
ORDER BY total_items_sold DESC;

-- ============================================================
-- BUSINESS QUESTION 13
-- Which product categories had the highest Average Order Value?
-- ============================================================

WITH category_order_value AS (
    SELECT
        order_id,
        product_category_name,
        SUM(price) AS category_order_value
    FROM public.vw_product_analysis
    WHERE order_status = 'Delivered'
    GROUP BY
        order_id,
        product_category_name
)

SELECT
    product_category_name,
    ROUND(AVG(category_order_value), 2) AS average_order_value
FROM category_order_value
GROUP BY product_category_name
ORDER BY average_order_value DESC;

-- ============================================================
-- BUSINESS QUESTION 14
-- Which individual products generated the highest revenue?
-- ============================================================
SELECT
    product_id,
    product_category_name,
    ROUND(SUM(price), 2) AS total_revenue
FROM public.vw_product_analysis
WHERE order_status = 'Delivered'
GROUP BY
    product_id,
    product_category_name
ORDER BY total_revenue DESC
LIMIT 10;

-- ============================================================
-- BUSINESS QUESTION 15
-- Which product categories had the highest average review score?
-- ============================================================

WITH order_category_reviews AS (
    SELECT DISTINCT
        order_id,
        product_category_name,
        avg_review_score
    FROM public.vw_product_analysis
    WHERE order_status = 'Delivered'
      AND avg_review_score IS NOT NULL
)
SELECT
    product_category_name,
    ROUND(AVG(avg_review_score), 2) AS avg_review_score,
    COUNT(*) AS reviewed_orders
FROM order_category_reviews
GROUP BY product_category_name
ORDER BY avg_review_score DESC
LIMIT 10;


-- ============================================================
-- BUSINESS QUESTION 16
-- How many customers are repeat customers?
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM public.vw_order_analysis
    WHERE order_status = 'Delivered'
    GROUP BY customer_unique_id
)

SELECT
    COUNT(*) AS repeat_customers
FROM customer_orders
WHERE total_orders > 1;

-- ============================================================
-- BUSINESS QUESTION 17
-- What percentage of customers are repeat customers?
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM public.vw_order_analysis
    WHERE order_status = 'Delivered'
    GROUP BY customer_unique_id
)

SELECT
    ROUND(
        100.0 *
        COUNT(*) FILTER (WHERE total_orders > 1)
        / COUNT(*),
        2
    ) AS repeat_customer_percentage
FROM customer_orders;

-- ============================================================
-- BUSINESS QUESTION 18
-- Which customers generated the highest revenue?
-- ============================================================

SELECT
    customer_unique_id,
    ROUND(SUM(total_product_value), 2) AS total_revenue
FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
GROUP BY customer_unique_id
ORDER BY total_revenue DESC
LIMIT 10;
-- ============================================================
-- BUSINESS QUESTION 19
-- What is the average number of orders per customer?
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS number_of_orders
    FROM public.vw_order_analysis
    WHERE order_status = 'Delivered'
    GROUP BY customer_unique_id
)

SELECT
    ROUND(AVG(number_of_orders), 2) AS avg_orders_per_customer
FROM customer_orders;
	

-- ============================================================
-- BUSINESS QUESTION 20
-- Which customer states generated the highest revenue?
-- ============================================================

SELECT
    customer_state,
    ROUND(SUM(total_product_value), 2) AS total_revenue
FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
GROUP BY customer_state
ORDER BY total_revenue DESC;

-- ============================================================
-- BUSINESS QUESTION 21
-- Which customer states had the highest number of delivered orders?
-- ============================================================
SELECT
    customer_state,
    COUNT(order_id) AS delivered_orders
FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
GROUP BY customer_state
ORDER BY delivered_orders DESC;
-- ============================================================
-- BUSINESS QUESTION 22
-- Which customer cities generated the highest revenue?
-- Use delivered orders only.
-- ============================================================
SELECT
    customer_city,
    ROUND(SUM(total_product_value), 2) AS revenue_per_city
FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
GROUP BY customer_city
ORDER BY revenue_per_city DESC
LIMIT 10;
-- ============================================================
-- BUSINESS QUESTION 23
-- What is the Average Order Value by customer state?
-- ============================================================

SELECT
    customer_state,
    ROUND(AVG(total_product_value), 2) AS aov_per_state
FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
GROUP BY customer_state
ORDER BY aov_per_state DESC;

-- ============================================================
-- BUSINESS QUESTION 24
-- Which states have high order volume but relatively low revenue?
-- ============================================================

SELECT
    customer_state,
    COUNT(order_id) AS order_volume,
    ROUND(SUM(total_product_value), 2) AS total_revenue,
    ROUND(AVG(total_product_value), 2) AS avg_order_value
FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
GROUP BY customer_state
ORDER BY
    order_volume DESC,
    total_revenue ASC;

-- ============================================================
-- BUSINESS QUESTION 25
-- What percentage of total revenue comes from each customer state?
-- ============================================================

SELECT
    customer_state,
    ROUND(SUM(total_product_value), 2) AS state_revenue,

    ROUND(
        100.0 * SUM(total_product_value)
        / SUM(SUM(total_product_value)) OVER (),
        2
    ) AS pct_total_revenue

FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
GROUP BY customer_state
ORDER BY pct_total_revenue DESC;

-- ============================================================
-- BUSINESS QUESTION 26
-- What percentage of delivered orders were late?
-- ============================================================

SELECT
    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE delivery_performance = 'Late'
        )
        /
        COUNT(*),
        2
    ) AS pct_late_deliveries
FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
  AND delivery_performance IN ('Late', 'On Time / Early');

-- ============================================================
-- BUSINESS QUESTION 27
-- What is the average delivery time in days?
-- ============================================================

SELECT
    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    order_delivered_customer_date
                    - order_purchase_timestamp
                )
            ) / 86400.0
        ),
        2
    ) AS avg_delivery_days
FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
  AND order_delivered_customer_date IS NOT NULL;
-- ============================================================
-- BUSINESS QUESTION 28
-- Which customer states have the highest late-delivery rate?
-- ============================================================

SELECT
    customer_state,
    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE delivery_performance = 'Late'
        )
        / COUNT(*),
        2
    ) AS late_delivery_rate
FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
  AND delivery_performance IN ('Late', 'On Time / Early')
GROUP BY customer_state
ORDER BY late_delivery_rate DESC;
-- ============================================================
-- BUSINESS QUESTION 29
-- Do late deliveries receive lower review scores?
-- ============================================================

SELECT
    delivery_performance,
    ROUND(AVG(avg_review_score), 2) AS avg_review_score
FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
  AND delivery_performance IN ('Late', 'On Time / Early')
  AND avg_review_score IS NOT NULL
GROUP BY delivery_performance
ORDER BY avg_review_score DESC;

-- ============================================================
-- BUSINESS QUESTION 30
-- Which states have the longest average delivery time?
-- ============================================================

SELECT
    customer_state,
    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    order_delivered_customer_date
                    - order_purchase_timestamp
                )
            ) / 86400.0
        ),
        2
    ) AS avg_delivery_days
FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
  AND order_delivered_customer_date IS NOT NULL
GROUP BY customer_state
ORDER BY avg_delivery_days DESC;


-- ============================================================
-- BUSINESS QUESTION 31
-- What is the overall average review score?
-- Grain: 1 row per review record
-- ============================================================

SELECT
    ROUND(AVG(review_score), 2) AS overall_avg_review_score
FROM public.olist_order_reviews_clean;


-- ============================================================
-- BUSINESS QUESTION 32
-- How are review scores distributed?
-- Grain: 1 row per review record
-- ============================================================

SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_reviews
FROM public.olist_order_reviews_clean
GROUP BY review_score
ORDER BY review_score;
-- ============================================================
-- BUSINESS QUESTION 33
-- Which product categories have the lowest average review scores?
-- ============================================================

WITH order_category_reviews AS (
    SELECT DISTINCT
        order_id,
        product_category_name,
        avg_review_score
    FROM public.vw_product_analysis
    WHERE avg_review_score IS NOT NULL
)

SELECT
    product_category_name,
    ROUND(AVG(avg_review_score), 2) AS avg_review_score,
    COUNT(*) AS reviewed_orders
FROM order_category_reviews
GROUP BY product_category_name
ORDER BY avg_review_score ASC;
-- ============================================================
-- BUSINESS QUESTION 34
-- How does delivery delay affect review score?
-- Compare average review score by delivery performance.
-- ============================================================
SELECT
    delivery_performance,
    ROUND(AVG(avg_review_score), 2) AS avg_review_score
FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
  AND delivery_performance IN ('Late', 'On Time / Early')
  AND avg_review_score IS NOT NULL
GROUP BY delivery_performance
ORDER BY avg_review_score;

-- ============================================================
-- BUSINESS QUESTION 35
-- Which delivered orders received poor reviews despite being on time?
-- ============================================================

SELECT
    order_id,
    avg_review_score
FROM public.vw_order_analysis
WHERE order_status = 'Delivered'
  AND delivery_performance = 'On Time / Early'
  AND avg_review_score <= 2
ORDER BY avg_review_score ASC;

-- ============================================================
-- BUSINESS QUESTION 36
-- Which sellers generated the highest revenue?
-- Use delivered orders only.
-- ============================================================
SELECT
    seller_id,
    ROUND(SUM(price), 2) AS total_revenue
FROM public.vw_product_analysis
WHERE order_status = 'Delivered'
GROUP BY seller_id
ORDER BY total_revenue DESC
LIMIT 10;
-- ============================================================
-- BUSINESS QUESTION 37
-- Which sellers handled the highest number of delivered orders?
-- ============================================================
SELECT
    seller_id,
    COUNT(DISTINCT order_id) AS number_of_delivered_orders
FROM vw_product_analysis
WHERE order_status = 'Delivered'
GROUP BY seller_id
ORDER BY number_of_delivered_orders DESC
LIMIT 10;

-- ============================================================
-- BUSINESS QUESTION 38
-- Which sellers have the highest Average Order Value?
-- ============================================================

WITH seller_order_value AS (
    SELECT
        seller_id,
        order_id,
        SUM(price) AS seller_order_value
    FROM public.vw_product_analysis
    WHERE order_status = 'Delivered'
    GROUP BY
        seller_id,
        order_id
)

SELECT
    seller_id,
    ROUND(AVG(seller_order_value), 2) AS avg_order_value
FROM seller_order_value
GROUP BY seller_id
ORDER BY avg_order_value DESC
LIMIT 10;

-- ============================================================
-- BUSINESS QUESTION 39
-- Which sellers have high revenue but low average review scores?
-- ============================================================

WITH seller_order_level AS (
    SELECT
        seller_id,
        order_id,
        SUM(price) AS order_revenue,
        MAX(avg_review_score) AS review_score
    FROM public.vw_product_analysis
    WHERE order_status = 'Delivered'
    GROUP BY
        seller_id,
        order_id
),

seller_metrics AS (
    SELECT
        seller_id,
        SUM(order_revenue) AS total_revenue,
        AVG(review_score) AS avg_review_score,
        COUNT(*) FILTER (
            WHERE review_score IS NOT NULL
        ) AS reviewed_orders
    FROM seller_order_level
    GROUP BY seller_id
)

SELECT
    seller_id,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(avg_review_score, 2) AS avg_review_score,
    reviewed_orders
FROM seller_metrics
WHERE avg_review_score < 3
ORDER BY total_revenue DESC;
-- ============================================================
-- BUSINESS QUESTION 40
-- Which sellers have the highest late-delivery rate?
-- ============================================================

WITH seller_delivery_stats AS (
    SELECT
        seller_id,

        COUNT(DISTINCT order_id) AS total_delivered_orders,

        COUNT(DISTINCT order_id) FILTER (
            WHERE delivery_performance = 'Late'
        ) AS late_delivered_orders

    FROM public.vw_product_analysis
    WHERE order_status = 'Delivered'
      AND delivery_performance IN ('Late', 'On Time / Early')
    GROUP BY seller_id
)

SELECT
    seller_id,
    total_delivered_orders,
    late_delivered_orders,

    ROUND(
        100.0 * late_delivered_orders
        / NULLIF(total_delivered_orders, 0),
        2
    ) AS late_delivery_rate

FROM seller_delivery_stats
WHERE total_delivered_orders >= 20
ORDER BY late_delivery_rate DESC;

-- ============================================================
-- END OF SQL ANALYSIS
-- 40 business questions completed.
-- Next stage: KPI extraction, business insights, Tableau, GitHub.
-- ============================================================



/*
===============================================================================
OLIST E-COMMERCE: KPI VIEW LAYER
Purpose: consolidate the headline numbers scattered across the 40 business
questions into a small set of dashboard-ready views for Tableau, so Tableau
queries these directly instead of re-deriving the same logic in calculated
fields.
===============================================================================
*/


-- ============================================================
-- VIEW 1: vw_kpi_summary
-- Grain: 1 single row — the dashboard's headline tiles
-- ============================================================

CREATE OR REPLACE VIEW vw_kpi_summary AS
SELECT
    -- Volume --------------------------------------------------
    (SELECT COUNT(*) FROM vw_order_analysis) AS total_orders,

    (SELECT COUNT(DISTINCT customer_unique_id)
     FROM vw_order_analysis) AS unique_customers,

    -- Revenue -------------------------------------------------
    (SELECT ROUND(SUM(total_product_value), 2)
     FROM vw_order_analysis
     WHERE order_status = 'Delivered') AS total_revenue,

    (SELECT ROUND(AVG(total_product_value), 2)
     FROM vw_order_analysis
     WHERE order_status = 'Delivered') AS avg_order_value,

    -- Delivery performance --------------------------------------
    (SELECT ROUND(
        100.0 * COUNT(*) FILTER (WHERE order_status = 'Delivered')
        / COUNT(*), 2)
     FROM vw_order_analysis) AS pct_orders_delivered,

    (SELECT ROUND(
        100.0 * COUNT(*) FILTER (WHERE delivery_performance = 'Late')
        / COUNT(*), 2)
     FROM vw_order_analysis
     WHERE order_status = 'Delivered'
       AND delivery_performance IN ('Late', 'On Time / Early')
    ) AS pct_late_deliveries,

    (SELECT ROUND(AVG(
        EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 86400.0
     ), 2)
     FROM vw_order_analysis
     WHERE order_status = 'Delivered'
       AND order_delivered_customer_date IS NOT NULL
    ) AS avg_delivery_days,

    -- Customer behavior -----------------------------------------
    (SELECT ROUND(
        100.0 * COUNT(*) FILTER (WHERE total_orders > 1) / COUNT(*), 2)
     FROM (
        SELECT customer_unique_id, COUNT(DISTINCT order_id) AS total_orders
        FROM vw_order_analysis
        WHERE order_status = 'Delivered'
        GROUP BY customer_unique_id
     ) customer_orders
    ) AS pct_repeat_customers,

    (SELECT ROUND(AVG(total_orders), 2)
     FROM (
        SELECT customer_unique_id, COUNT(DISTINCT order_id) AS total_orders
        FROM vw_order_analysis
        WHERE order_status = 'Delivered'
        GROUP BY customer_unique_id
     ) customer_orders
    ) AS avg_orders_per_customer,

    -- Customer satisfaction ---------------------------------------
    (SELECT ROUND(AVG(review_score), 2)
     FROM olist_order_reviews_clean) AS overall_avg_review_score,

    (SELECT ROUND(
        100.0 * COUNT(*) FILTER (WHERE review_score <= 2) / COUNT(*), 2)
     FROM olist_order_reviews_clean) AS pct_low_reviews;
-- Each metric is its own scalar subquery (same pattern you already used
-- in EDA 01: Dataset Overview), so this view always returns exactly ONE
-- row — the full set of headline KPIs, ready to drop straight onto a
-- Tableau dashboard as single-value tiles. Each subquery is independent,
-- so a NULL or zero in one metric never affects the others.

SELECT * FROM vw_kpi_summary;


-- ============================================================
-- VIEW 2: vw_kpi_by_state
-- Grain: 1 row per customer_state
-- Purpose: consolidates BQ20/21/23/24/25/28/30 — all the revenue,
-- volume, AOV and delivery breakdowns that were previously five
-- separate "by state" questions collapse into one view here, with
-- Tableau handling which metric to chart via filters.
-- ============================================================

CREATE OR REPLACE VIEW vw_kpi_by_state AS
SELECT
    customer_state,

    COUNT(order_id)                         AS order_volume,
    ROUND(SUM(total_product_value), 2)         AS total_revenue,
    ROUND(AVG(total_product_value), 2)           AS avg_order_value,

    ROUND(
        100.0 * SUM(total_product_value)
        / SUM(SUM(total_product_value)) OVER (),
        2
    ) AS pct_of_total_revenue,

    ROUND(
        100.0 * COUNT(*) FILTER (WHERE delivery_performance = 'Late')
        / NULLIF(COUNT(*) FILTER (WHERE delivery_performance IN ('Late','On Time / Early')), 0),
        2
    ) AS late_delivery_rate,

    ROUND(AVG(
        EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 86400.0
    ) FILTER (WHERE order_delivered_customer_date IS NOT NULL), 2)
        AS avg_delivery_days

FROM vw_order_analysis
WHERE order_status = 'Delivered'
GROUP BY customer_state;

SELECT * FROM vw_kpi_by_state ORDER BY total_revenue DESC;


-- ============================================================
-- VIEW 3: vw_kpi_by_category
-- Grain: 1 row per product_category_name
-- Purpose: consolidates BQ11/12/13/15/33 — category revenue,
-- volume and review performance in one place.
-- ============================================================

CREATE OR REPLACE VIEW vw_kpi_by_category AS
WITH category_order_value AS (
    SELECT
        order_id,
        product_category_name,
        SUM(price) AS category_order_value
    FROM vw_product_analysis
    WHERE order_status = 'Delivered'
    GROUP BY order_id, product_category_name
),

category_reviews AS (
    SELECT DISTINCT
        order_id,
        product_category_name,
        avg_review_score
    FROM vw_product_analysis
    WHERE order_status = 'Delivered'
      AND avg_review_score IS NOT NULL
)

SELECT
    pa.product_category_name,

    COUNT(*)                                    AS total_items_sold,
    ROUND(SUM(pa.price), 2)                        AS total_revenue,

    ROUND(AVG(cov.category_order_value), 2)          AS avg_order_value,

    ROUND(AVG(cr.avg_review_score), 2)                 AS avg_review_score,
    COUNT(DISTINCT cr.order_id)                          AS reviewed_orders

FROM vw_product_analysis pa

LEFT JOIN category_order_value cov
    ON pa.order_id = cov.order_id
   AND pa.product_category_name = cov.product_category_name

LEFT JOIN category_reviews cr
    ON pa.order_id = cr.order_id
   AND pa.product_category_name = cr.product_category_name

WHERE pa.order_status = 'Delivered'
GROUP BY pa.product_category_name;
-- Built from two CTEs at the ORDER-category grain (category_order_value,
-- category_reviews) joined back to the item-level vw_product_analysis,
-- to avoid double-counting AOV/review scores the way a naive single
-- GROUP BY on item rows would — same grain-control principle your
-- project notes call out at the top of the script.

SELECT * FROM vw_kpi_by_category ORDER BY total_revenue DESC;


-- ============================================================
-- VIEW 4: vw_kpi_by_seller
-- Grain: 1 row per seller_id
-- Purpose: consolidates BQ36/37/38/39/40 — the seller performance
-- + risk-flag metrics (high revenue but low review score, high
-- late-delivery rate) in one place.
-- ============================================================

CREATE OR REPLACE VIEW vw_kpi_by_seller AS
WITH seller_order_level AS (
    SELECT
        seller_id,
        order_id,
        SUM(price) AS order_revenue,
        MAX(avg_review_score) AS review_score,
        MAX(delivery_performance) AS delivery_performance
    FROM vw_product_analysis
    WHERE order_status = 'Delivered'
    GROUP BY seller_id, order_id
)

SELECT
    seller_id,

    COUNT(*)                                      AS total_delivered_orders,
    ROUND(SUM(order_revenue), 2)                      AS total_revenue,
    ROUND(AVG(order_revenue), 2)                        AS avg_order_value,

    ROUND(AVG(review_score), 2)                           AS avg_review_score,
    COUNT(*) FILTER (WHERE review_score IS NOT NULL)        AS reviewed_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (WHERE delivery_performance = 'Late')
        / NULLIF(COUNT(*) FILTER (WHERE delivery_performance IN ('Late','On Time / Early')), 0),
        2
    ) AS late_delivery_rate,

    CASE
        WHEN AVG(review_score) < 3 THEN 1 ELSE 0
    END AS low_review_flag
    -- Flags sellers with high revenue but poor satisfaction (BQ39) —
    -- a direct, pre-computed risk indicator rather than something
    -- Tableau has to recompute.

FROM seller_order_level
GROUP BY seller_id;

SELECT * FROM vw_kpi_by_seller
WHERE total_delivered_orders >= 20
ORDER BY total_revenue DESC;
-- Note: the >= 20 order threshold (same one your BQ40 used, to avoid
-- a seller with 1 order and 1 late delivery showing a misleading 100%
-- late rate) is applied here at QUERY time, not baked into the view
-- itself — so Tableau can still see every seller's raw numbers and
-- adjust the threshold as a filter if needed.


-- ================================================================
-- OLIST KPI VIEW LAYER — INLINE METADATA
-- Attaches the data dictionary to the database itself via Postgres
-- COMMENT ON, so the definitions are visible from psql (\d+ view_name)
-- or pgAdmin's object properties, not just the GitHub markdown file.
-- Full definitions, units, assumptions and [NEEDS REVIEW] notes live
-- in: docs/kpi_data_dictionary.md
-- Run this AFTER creating the 4 views in olist_kpi_views.sql.
-- ================================================================


-- ============================================================
-- VIEW 1: vw_kpi_summary
-- ============================================================
COMMENT ON VIEW vw_kpi_summary IS
'Single-row dashboard header: volume, revenue, delivery, retention and satisfaction KPIs. Full definitions: docs/kpi_data_dictionary.md';

COMMENT ON COLUMN vw_kpi_summary.total_orders IS
'Count of all orders, any status (not filtered to Delivered).';
COMMENT ON COLUMN vw_kpi_summary.unique_customers IS
'Distinct customer_unique_id across all orders.';
COMMENT ON COLUMN vw_kpi_summary.total_revenue IS
'Sum of total_product_value for Delivered orders only, in BRL.';
COMMENT ON COLUMN vw_kpi_summary.avg_order_value IS
'Avg total_product_value for Delivered orders, in BRL.';
COMMENT ON COLUMN vw_kpi_summary.pct_orders_delivered IS
'% of ALL orders with order_status = Delivered.';
COMMENT ON COLUMN vw_kpi_summary.pct_late_deliveries IS
'% of delivered orders with delivery_performance = Late. Denominator excludes orders with unknown delivery_performance.';
COMMENT ON COLUMN vw_kpi_summary.avg_delivery_days IS
'Avg days between order_purchase_timestamp and order_delivered_customer_date, delivered orders with a known delivery date only.';
COMMENT ON COLUMN vw_kpi_summary.pct_repeat_customers IS
'% of delivered-order customers with 2+ distinct orders.';
COMMENT ON COLUMN vw_kpi_summary.avg_orders_per_customer IS
'Avg distinct delivered orders per customer.';
COMMENT ON COLUMN vw_kpi_summary.overall_avg_review_score IS
'Avg review_score (1-5 scale) across all reviews.';
COMMENT ON COLUMN vw_kpi_summary.pct_low_reviews IS
'% of reviews with review_score <= 2.';


-- ============================================================
-- VIEW 2: vw_kpi_by_state
-- ============================================================
COMMENT ON VIEW vw_kpi_by_state IS
'Revenue, volume, AOV and delivery performance by customer_state. Delivered orders only. Full definitions: docs/kpi_data_dictionary.md';

COMMENT ON COLUMN vw_kpi_by_state.customer_state IS
'Brazilian state code of the customer (2-letter). Grouping key.';
COMMENT ON COLUMN vw_kpi_by_state.order_volume IS
'Count of delivered orders in this state.';
COMMENT ON COLUMN vw_kpi_by_state.total_revenue IS
'Sum of total_product_value for delivered orders in this state, BRL.';
COMMENT ON COLUMN vw_kpi_by_state.avg_order_value IS
'Avg total_product_value for delivered orders in this state, BRL.';
COMMENT ON COLUMN vw_kpi_by_state.pct_of_total_revenue IS
'This state''s share of total revenue across all states (window function, sums to ~100% across rows).';
COMMENT ON COLUMN vw_kpi_by_state.late_delivery_rate IS
'% of this state''s delivered orders that were late. NULLIF-guarded against divide-by-zero.';
COMMENT ON COLUMN vw_kpi_by_state.avg_delivery_days IS
'Avg delivery time for this state, in days. NULL if no delivered orders have a delivery date on record.';


-- ============================================================
-- VIEW 3: vw_kpi_by_category
-- ============================================================
COMMENT ON VIEW vw_kpi_by_category IS
'Revenue, volume and review performance by product_category_name. Built via order-category grain CTEs to avoid double-counting. Full definitions: docs/kpi_data_dictionary.md';

COMMENT ON COLUMN vw_kpi_by_category.product_category_name IS
'Product category. Grouping key.';
COMMENT ON COLUMN vw_kpi_by_category.total_items_sold IS
'Count of item-level rows in this category (item grain, not order grain).';
COMMENT ON COLUMN vw_kpi_by_category.total_revenue IS
'Sum of item price for this category, BRL.';
COMMENT ON COLUMN vw_kpi_by_category.avg_order_value IS
'Avg per-order value for orders containing this category, computed at order-category grain to avoid double-counting multi-item orders.';
COMMENT ON COLUMN vw_kpi_by_category.avg_review_score IS
'Avg review score (1-5 scale) for orders containing this category. NULL if no reviewed orders exist for the category.';
COMMENT ON COLUMN vw_kpi_by_category.reviewed_orders IS
'Count of distinct reviewed orders for this category.';


-- ============================================================
-- VIEW 4: vw_kpi_by_seller
-- ============================================================
COMMENT ON VIEW vw_kpi_by_seller IS
'Revenue, review and delivery performance by seller_id, with a low-review risk flag. Filter total_delivered_orders >= 20 for reliable rates. Full definitions: docs/kpi_data_dictionary.md';

COMMENT ON COLUMN vw_kpi_by_seller.seller_id IS
'Seller identifier. Grouping key.';
COMMENT ON COLUMN vw_kpi_by_seller.total_delivered_orders IS
'Count of distinct delivered orders for this seller.';
COMMENT ON COLUMN vw_kpi_by_seller.total_revenue IS
'Sum of per-order revenue for this seller, BRL.';
COMMENT ON COLUMN vw_kpi_by_seller.avg_order_value IS
'Avg per-order revenue for this seller, BRL.';
COMMENT ON COLUMN vw_kpi_by_seller.avg_review_score IS
'Avg review score (1-5 scale) across this seller''s orders. NULL if no reviewed orders.';
COMMENT ON COLUMN vw_kpi_by_seller.reviewed_orders IS
'Count of this seller''s orders with a non-null review score.';
COMMENT ON COLUMN vw_kpi_by_seller.late_delivery_rate IS
'% of this seller''s orders that were late. NULLIF-guarded against divide-by-zero.';
COMMENT ON COLUMN vw_kpi_by_seller.low_review_flag IS
'1 if avg_review_score < 3, else 0. Pre-computed risk indicator (high revenue / low satisfaction sellers).';


-- ================================================================
-- VERIFY: comments are visible via information_schema or psql \d+
-- ================================================================
SELECT
    c.relname  AS view_name,
    a.attname  AS column_name,
    d.description
FROM pg_class c
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum > 0
LEFT JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = a.attnum
WHERE c.relname IN ('vw_kpi_summary','vw_kpi_by_state','vw_kpi_by_category','vw_kpi_by_seller')
ORDER BY c.relname, a.attnum;
