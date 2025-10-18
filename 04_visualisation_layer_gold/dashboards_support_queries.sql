-- ===============================================================
-- ANALYSIS: Average yearly units (NSW + VIC) vs national average
-- Description:
--   Calculates average annual sales for NSW + VIC combined,
--   compares against average national sales across all states.
-- ===============================================================

WITH yearly_total AS (
    SELECT
        YEAR(order_date) AS order_year,
        SUM(total_units_sold) AS yearly_units
    FROM NOVA_VIS_DB.VIS_SCHEMA.VIS_PRODUCT_SALES_STATE
    WHERE delivery_state IN ('NSW', 'VIC')
    GROUP BY YEAR(order_date)
),
total_avg_units AS (
    SELECT
        ROUND(AVG(yearly_units), 2) AS avg_units_nsw_vic
    FROM yearly_total
),
total_avg_all AS (
    SELECT
        ROUND(AVG(yearly_units), 2) AS avg_units_all
    FROM (
        SELECT
            YEAR(order_date) AS order_year,
            SUM(total_units_sold) AS yearly_units
        FROM NOVA_VIS_DB.VIS_SCHEMA.VIS_PRODUCT_SALES_STATE
        GROUP BY YEAR(order_date)
    )
)
SELECT
    'NSW + VIC' AS delivery_state,
    t.avg_units_nsw_vic,
    TO_CHAR(ROUND(100.0 * t.avg_units_nsw_vic / a.avg_units_all, 2)) || '%' AS percent_of_total_avg_sales
FROM total_avg_units t
CROSS JOIN total_avg_all a;

-- ===============================================================
-- ANALYSIS: NSW average yearly sales vs national average
-- ===============================================================

WITH yearly_total AS (
    SELECT
        YEAR(order_date) AS order_year,
        SUM(total_units_sold) AS yearly_units
    FROM NOVA_VIS_DB.VIS_SCHEMA.VIS_PRODUCT_SALES_STATE
    WHERE delivery_state = 'NSW'
    GROUP BY YEAR(order_date)
),
total_avg_units AS (
    SELECT
        ROUND(AVG(yearly_units), 2) AS avg_units_nsw
    FROM yearly_total
),
total_avg_all AS (
    SELECT
        ROUND(AVG(yearly_units), 2) AS avg_units_all
    FROM (
        SELECT
            YEAR(order_date) AS order_year,
            SUM(total_units_sold) AS yearly_units
        FROM NOVA_VIS_DB.VIS_SCHEMA.VIS_PRODUCT_SALES_STATE
        GROUP BY YEAR(order_date)
    )
)
SELECT
    'NSW' AS delivery_state,
    t.avg_units_nsw,
    TO_CHAR(ROUND(100.0 * t.avg_units_nsw / a.avg_units_all, 2)) || '%' AS percent_of_total_avg_sales
FROM total_avg_units t
CROSS JOIN total_avg_all a;

-- ===============================================================
-- ANALYSIS: VIC average yearly sales vs national average
-- ===============================================================

WITH yearly_total AS (
    SELECT
        YEAR(order_date) AS order_year,
        SUM(total_units_sold) AS yearly_units
    FROM NOVA_VIS_DB.VIS_SCHEMA.VIS_PRODUCT_SALES_STATE
    WHERE delivery_state = 'VIC'
    GROUP BY YEAR(order_date)
),
total_avg_units AS (
    SELECT
        ROUND(AVG(yearly_units), 2) AS avg_units_vic
    FROM yearly_total
),
total_avg_all AS (
    SELECT
        ROUND(AVG(yearly_units), 2) AS avg_units_all
    FROM (
        SELECT
            YEAR(order_date) AS order_year,
            SUM(total_units_sold) AS yearly_units
        FROM NOVA_VIS_DB.VIS_SCHEMA.VIS_PRODUCT_SALES_STATE
        GROUP BY YEAR(order_date)
    )
)
SELECT
    'VIC' AS delivery_state,
    t.avg_units_vic,
    TO_CHAR(ROUND(100.0 * t.avg_units_vic / a.avg_units_all, 2)) || '%' AS percent_of_total_avg_sales
FROM total_avg_units t
CROSS JOIN total_avg_all a;

-- ===============================================================
-- Sale quantity for each state 2022-2024
-- ===============================================================

SELECT * FROM NOVA_VIS_DB.VIS_SCHEMA.V_TOTAL_SALES;

-- ===============================================================
-- Top 3 sellers in NSW
-- ===============================================================

SELECT * FROM NOVA_VIS_DB.VIS_SCHEMA.V_SALE_EACH_STATE
WHERE delivery_state = 'NSW';

-- ===============================================================
-- Top 3 sellers in VIC
-- ===============================================================

SELECT * FROM NOVA_VIS_DB.VIS_SCHEMA.V_SALE_EACH_STATE
WHERE delivery_state = 'VIC';


--TOTAL REVENUE 2022

CREATE OR REPLACE VIEW nova_db.nova_schema.revenue_2022 AS
SELECT
    order_date::date AS order_date,
    total_price::number(10,2) AS total_price
FROM fact_order
WHERE EXTRACT(YEAR FROM order_date::date) = 2022;

SELECT SUM(v.total_price),
ROUND(SUM(v.total_price)/sum(v.total_price)) as pct_act
from revenue_2022 as v;


--Revenue in 2023 compared with 2022

CREATE OR REPLACE VIEW nova_db.nova_schema.revenue_2023 AS
SELECT
    order_date::date AS order_date,
    total_price::number(10,2) AS total_price
FROM fact_order
WHERE EXTRACT(YEAR FROM order_date::date) = 2023;

SELECT
  (SELECT SUM(total_price) FROM revenue_2022) AS total_revenue_2022,
  (SELECT SUM(total_price) FROM revenue_2023) AS total_revenue_2023,
  ROUND(
    (SELECT SUM(total_price) FROM revenue_2023)
    / NULLIF((SELECT SUM(total_price) FROM revenue_2022), 0), 2) AS pct_act;


Revenue in 2024 compared with 2023

CREATE OR REPLACE VIEW nova_db.nova_schema.revenue_2024 AS
SELECT
    order_date::date AS order_date,
    total_price::number(10,2) AS total_price
FROM fact_order
WHERE EXTRACT(YEAR FROM order_date::date) = 2024;

SELECT
  (SELECT SUM(total_price) FROM revenue_2024) AS total_revenue_2024,
  (SELECT SUM(total_price) FROM revenue_2023) AS total_revenue_2023,
  ROUND(
    (SELECT SUM(total_price) FROM revenue_2024)
    / NULLIF((SELECT SUM(total_price) FROM revenue_2023), 0), 2) AS pct_act;

--Revenue by city in 2022 (AUD)

USE ROLE NOVA_ROLE;
CREATE WAREHOUSE IF NOT EXISTS NOVA_WH INITIALLY_SUSPENDED=TRUE;
USE WAREHOUSE NOVA_WH;
USE SCHEMA NOVA_DB.NOVA_SCHEMA;



SELECT  c.city, SUM(o.total_price)
FROM DIM_DELIVERY AS c
JOIN FACT_Order AS o
ON c.delivery_id = o.delivery_id
WHERE o.order_date BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY c.city;

--Revenue by city in 2023 (AUD)

USE ROLE NOVA_ROLE;
CREATE WAREHOUSE IF NOT EXISTS NOVA_WH INITIALLY_SUSPENDED=TRUE;
USE WAREHOUSE NOVA_WH;
USE SCHEMA NOVA_DB.NOVA_SCHEMA;



SELECT  c.city, SUM(o.total_price)
FROM DIM_DELIVERY AS c
JOIN FACT_Order AS o
ON c.delivery_id = o.delivery_id
WHERE o.order_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY c.city;

--Revenue by city in 2024 (AUD)
USE ROLE NOVA_ROLE;
CREATE WAREHOUSE IF NOT EXISTS NOVA_WH INITIALLY_SUSPENDED=TRUE;
USE WAREHOUSE NOVA_WH;
USE SCHEMA NOVA_DB.NOVA_SCHEMA;


SELECT  c.city, SUM(o.total_price)
FROM DIM_DELIVERY AS c
JOIN FACT_Order AS o
ON c.delivery_id = o.delivery_id
WHERE o.order_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY c.city;


--Stock Level (Top 5 Selling Product)
CREATE OR REPLACE VIEW NOVA_VIS_DB.VIS_SCHEMA.V_BESTSELLERS_AUS_ALL_YEARS AS
 WITH total_product_sales AS (
 	SELECT
         product_name,                                  -- Product name
     	SUM(total_units_sold) AS total_quantity_sold,  -- Total quantity sold across all years and states
     	ROW_NUMBER() OVER (
         	ORDER BY SUM(total_units_sold) DESC     	-- Rank by highest total quantity sold
     	) AS product_rank
 	FROM
         NOVA_VIS_DB.VIS_SCHEMA.VIS_PRODUCT_SALES_STATE
 	GROUP BY
     	product_name
 )



SELECT
 	'2022–2024' AS year_range,                          -- Static year column for labeling
 	product_name,
 	total_quantity_sold
 FROM
 	total_product_sales
 WHERE
 	product_rank <= 5                                   -- Only top 5 products
 ORDER BY
 	product_rank;
 
 
--Stock Level (31 Dec 2024)
 
USE ROLE NOVA_ROLE;
CREATE warehouse IF NOT EXISTS NOVA_WH;
-- INITIALLY_s
USE WAREHOUSE NOVA_WH;
USE SCHEMA NOVA_DB.nova_schema;
 
uspended = TRUE;
USE WAREHOUSE NOVA_WH;
USE SCHEMA NOVA_DB.nova_schema;
 
select quantity, product_name
from dim_product
where quantity <=10;





---------------------------LOAN---------------------------------
-- VISUALISATION 1: TOTAL REVENUE BY CUSTOMER SEGMENT
------------------------------------------------------------
-- Business Question:
-- "Which customer segments (Platinum, Gold, Silver, Bronze)
-- contribute the most to NovaShop’s total revenue?"

-- Purpose:
-- This view categorises customers based on their total spending
-- and helps business teams identify high-value (Platinum/Gold)
-- customers for loyalty and retention strategies.

-- ---------------------------------------------------------
-- Customer Segment Definitions:
-- ---------------------------------------------------------
-- Platinum: Top 10% of customers by total revenue
--     → These are the most valuable customers — high spenders
--       who contribute disproportionately to total revenue.
--
-- Gold: Next 20% (between 10%–30%)
--     → Loyal and frequent buyers with above-average spending.
--
-- Silver: Next 40% (between 30%–70%)
--     → Regular customers with moderate purchase value.
--
-- Bronze: Bottom 30% (below 70%)
--     → Low-spend or occasional customers — often new or inactive.
--
-- These segments allow NovaShop to analyse customer behaviour
-- and prioritise marketing, loyalty, and retention strategies.
------------------------------------------------------------

-- 1. Activate the compute warehouse
USE WAREHOUSE NOVA_WH;

-- 2. Set working database and schema for visualisation outputs
USE DATABASE NOVA_VIS_DB;
USE SCHEMA VIS_SCHEMA;

------------------------------------------------------------
-- Create a view that aggregates customer revenue and assigns
-- each customer to a spending segment using percentile ranking.
------------------------------------------------------------

CREATE OR REPLACE VIEW V_CUSTOMER_REVENUE_SEGMENT AS
SELECT 
    c.CUSTOMER_ID,
    c.CUS_NAME,

    -- Calculate the total revenue per customer
    ROUND(SUM(f.TOTAL_PRICE), 2) AS TOTAL_REVENUE,

    -- Categorise customers by their spending percentile
    CASE 
        WHEN PERCENT_RANK() OVER (ORDER BY SUM(f.TOTAL_PRICE) DESC) <= 0.10 THEN 'Platinum'  -- Top 10% of customers
        WHEN PERCENT_RANK() OVER (ORDER BY SUM(f.TOTAL_PRICE) DESC) <= 0.30 THEN 'Gold'      -- Next 20%
        WHEN PERCENT_RANK() OVER (ORDER BY SUM(f.TOTAL_PRICE) DESC) <= 0.70 THEN 'Silver'    -- Next 40%
        ELSE 'Bronze'                                                                       -- Bottom 30%
    END AS REVENUE_SEGMENT

FROM NOVA_DB.NOVA_SCHEMA.FACT_ORDER f

-- Join FACT_ORDER with DIM_CUSTOMER to bring customer details
JOIN NOVA_DB.NOVA_SCHEMA.DIM_CUSTOMER c
    ON f.CUSTOMER_ID = c.CUSTOMER_ID

-- Group by each customer to calculate total spending
GROUP BY c.CUSTOMER_ID, c.CUS_NAME;

------------------------------------------------------------
-- Preview the resulting dataset to verify output
------------------------------------------------------------
SELECT * 
FROM VIS_SCHEMA.V_CUSTOMER_REVENUE_SEGMENT;

------------------------------------------------------------
-- VISUALISATION 2: TOP 20 CUSTOMERS BY TOTAL REVENUE
------------------------------------------------------------
-- Business Question:
-- "Who are NovaShop’s top 20 customers by total revenue,
-- and which revenue segment do they belong to?"

-- Purpose:
-- This chart highlights NovaShop’s most profitable customers,
-- helping business managers prioritise high-value clients for
-- marketing, rewards, or retention programs.

------------------------------------------------------------

-- 1. Reconfirm warehouse and schema (best practice)
USE WAREHOUSE NOVA_WH;
USE DATABASE NOVA_VIS_DB;
USE SCHEMA VIS_SCHEMA;

------------------------------------------------------------
-- Select top 20 customers based on total revenue
------------------------------------------------------------
SELECT 
    CUS_NAME,           -- Customer name
    TOTAL_REVENUE,      -- Their total spending value
    REVENUE_SEGMENT     -- Segment category (Platinum, Gold, Silver, Bronze)

FROM V_CUSTOMER_REVENUE_SEGMENT
ORDER BY TOTAL_REVENUE DESC   -- Rank by descending revenue
LIMIT 20;                     -- Return only top 20 customers





-- Visualization for LOGISTIC USE CASES —-------

---- a) Average Delivery Time by City---------------
----Goal: Identify which cities have slower or faster delivery times.--------
-----------------------------------------------------

USE DATABASE NOVA_VIS_DB;
USE SCHEMA VIS_SCHEMA;

SELECT * FROM V_DELIVERY_AREA;

----------------------------------------------------------------
---- b) Monthly Delivery Performance Trend----
----Goal: Track how delivery speed changes over time.
---------------------------------------------------------------

SELECT
    DELIVERY_YEAR_label,
    DELIVERY_MONTH,
    AVG(AVG_TIME) AS AVG_DELIVERY_TIME
FROM V_DELIVERY_SEASON
GROUP BY
    DELIVERY_YEAR_label,
    DELIVERY_MONTH
ORDER BY
    DELIVERY_YEAR_label,
    DELIVERY_MONTH;

----------------------------------------------------------------
---- c) On time delivery rate---- KPI Card for each
-- Goal: Monitor service reliability.
------------------------------------------------------

----- RATE in syd & mel-----------
SELECT 
    COUNT_IF(DELIVERY_TIME_DAYS <= 5) AS ON_TIME,
    COUNT(*) AS TOTAL,
    round((100 * COUNT_IF(DELIVERY_TIME_DAYS <= 5) / COUNT(*)),2) AS ON_TIME_PERCENT
FROM NOVA_DB.NOVA_SCHEMA.DIM_DELIVERY d
where d.city = 'Sydney';

SELECT 
    COUNT_IF(DELIVERY_TIME_DAYS <= 5) AS ON_TIME,
    COUNT(*) AS TOTAL,
    round((100 * COUNT_IF(DELIVERY_TIME_DAYS <= 5) / COUNT(*)),2) AS ON_TIME_PERCENT
FROM NOVA_DB.NOVA_SCHEMA.DIM_DELIVERY d
where d.city = 'Melbourne';

----- RATE other city-------------
SELECT 
    COUNT_IF(DELIVERY_TIME_DAYS <= 5) AS ON_TIME,
    COUNT(*) AS TOTAL,
    round((100 * COUNT_IF(DELIVERY_TIME_DAYS <= 5) / COUNT(*)),2) || '%' AS ON_TIME_PERCENT
FROM NOVA_DB.NOVA_SCHEMA.DIM_DELIVERY d
where d.city != 'Sydney' and d.city != 'Melbourne';










