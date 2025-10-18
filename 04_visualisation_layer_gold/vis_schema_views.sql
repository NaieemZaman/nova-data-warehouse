-- ===============================================================
-- TABLE: VIS_PRODUCT_SALES_STATE

-- This table stores aggregated product sales data by state and date.
-- It joins fact_order with dimension tables to enrich the data.
-- The output is used as a base for analytical dashboards and summary views.
-- ===============================================================

CREATE OR REPLACE TABLE NOVA_VIS_DB.VIS_SCHEMA.VIS_PRODUCT_SALES_STATE AS
SELECT
    p.product_name,                                 -- Name of the product
    d.state AS delivery_state,                      -- State to which the product was delivered
    f.order_date,                                   -- Date of the order
    SUM(f.order_quantity) AS total_units_sold       -- Total quantity sold (aggregated)
FROM
    NOVA_DB.NOVA_SCHEMA.FACT_ORDER f
JOIN
    NOVA_DB.NOVA_SCHEMA.DIM_PRODUCT p
    ON f.product_id = p.product_id
JOIN
    NOVA_DB.NOVA_SCHEMA.DIM_DELIVERY d
    ON f.delivery_id = d.delivery_id
GROUP BY
    f.order_date,
    d.state,
    p.product_name
ORDER BY
    d.state,
    f.order_date,
    total_units_sold DESC;

------------------------------------------------------------------
SELECT * FROM NOVA_VIS_DB.VIS_SCHEMA.VIS_PRODUCT_SALES_STATE;
------------------------------------------------------------------

-- ===============================================================
-- TABLE: V_TOTAL_SALES (VIEW)

-- This view summarizes total product quantities sold per year by state.
-- It provides a high-level time-series breakdown of total sales volume.
-- Useful for yearly trend analysis by region.
-- ===============================================================

CREATE OR REPLACE VIEW NOVA_VIS_DB.VIS_SCHEMA.V_TOTAL_SALES AS
SELECT
    YEAR(order_date) AS order_year,                     -- Extracted year from order date
    delivery_state,                                     -- State of delivery
    SUM(total_units_sold) AS total_quantity_sold        -- Total quantity sold in that year and state
FROM
    NOVA_VIS_DB.VIS_SCHEMA.VIS_PRODUCT_SALES_STATE
GROUP BY
    YEAR(order_date),
    delivery_state
ORDER BY
    order_year,
    delivery_state;

------------------------------------------------------------------
SELECT * FROM NOVA_VIS_DB.VIS_SCHEMA.V_TOTAL_SALES;
------------------------------------------------------------------

-- ===============================================================
-- TABLE: V_SALE_EACH_STATE (VIEW)

-- This view displays the top 3 best-selling products by state (NSW, VIC) and year.
-- Uses ROW_NUMBER() to rank products per state and year by total quantity sold.
-- Useful for identifying popular products in key regions.
-- ===============================================================

CREATE OR REPLACE VIEW NOVA_VIS_DB.VIS_SCHEMA.V_SALE_EACH_STATE AS
WITH product_sales_ranked AS (
    SELECT
        YEAR(order_date) AS order_year,                         -- Year extracted from order date
        delivery_state,                                         -- State of delivery
        product_name,                                           -- Name of the product
        SUM(total_units_sold) AS total_quantity_sold,           -- Total quantity sold
        ROW_NUMBER() OVER (
            PARTITION BY YEAR(order_date), delivery_state       -- Partition by year and state
            ORDER BY SUM(total_units_sold) DESC                 -- Rank by highest sales
        ) AS product_rank                                       -- Ranking of product within each state-year
    FROM
        NOVA_VIS_DB.VIS_SCHEMA.VIS_PRODUCT_SALES_STATE
    WHERE
        delivery_state IN ('NSW', 'VIC')                        -- Filter for NSW and VIC only
    GROUP BY
        YEAR(order_date),                                       
        delivery_state,                                         
        product_name                                            
)
SELECT
    order_year,                                                 -- Year of the order
    delivery_state,                                             -- State
    product_name,                                               -- Product name
    total_quantity_sold                                         -- Quantity sold
FROM
    product_sales_ranked
WHERE
    product_rank <= 3                                           -- Select only top 5 products per group
ORDER BY
    order_year,
    delivery_state,
    product_rank;

------------------------------------------------------------------
SELECT * FROM NOVA_VIS_DB.VIS_SCHEMA.V_SALE_EACH_STATE;
------------------------------------------------------------------

-----------------------------------------
--TABLE: CREATE GOLD TABLE FOR DELIVERY-------------
-----------------------------------------

USE DATABASE NOVA_VIS_DB;
USE SCHEMA VIS_SCHEMA;


CREATE OR REPLACE TABLE Vis_delivery_SUMMARY AS
SELECT DELIVERY_TIME_DAYS AS DELIVERY_TIME,
    delivery_month,
    delivery_year_label,
    CITY,
    STATE
FROM NOVA_DB.NOVA_SCHEMA.DIM_DELIVERY;

SELECT * FROM NOVA_VIS_DB.VIS_SCHEMA.Vis_delivery_SUMMARY;

-----------------------------------------
--VIEW: CREATE GOLD VIEW FOR DELIVERY-------------
-----------------------------------------

CREATE OR REPLACE VIEW V_DELIVERY_AREA AS
SELECT AVG(DELIVERY_TIME) AS AVG_TIME,
    CITY,
    STATE
FROM VIS_DELIVERY_SUMMARY
GROUP BY CITY, STATE;

SELECT * FROM NOVA_VIS_DB.VIS_SCHEMA.V_DELIVERY_AREA;

-----------------------------------------
--VIEW: CREATE GOLD VIEW FOR DELIVERY-------------
-----------------------------------------

CREATE OR REPLACE VIEW V_DELIVERY_SEASON AS
SELECT AVG(DELIVERY_TIME) AS AVG_TIME,
DELIVERY_MONTH,
DELIVERY_YEAR_LABEL
FROM VIS_DELIVERY_SUMMARY
GROUP BY DELIVERY_MONTH, DELIVERY_YEAR_LABEL;

SELECT * FROM NOVA_VIS_DB.VIS_SCHEMA.V_DELIVERY_SEASON;


----------------------------------------------------------------
--TOTAL REVENUE 2022

CREATE OR REPLACE VIEW nova_vis_db.vis_schema.revenue_2022 AS
SELECT
    order_date::date AS order_date,
    total_price::number(10,2) AS total_price
FROM nova_db.nova_schema.fact_order
WHERE EXTRACT(YEAR FROM order_date::date) = 2022;


--Revenue in 2023 compared with 2022
CREATE OR REPLACE VIEW nova_vis_db.vis_schema.revenue_2023 AS
SELECT
    order_date::date AS order_date,
    total_price::number(10,2) AS total_price
FROM nova_db.nova_schema.fact_order
WHERE EXTRACT(YEAR FROM order_date::date) = 2023;

-- Revenue in 2024 compared with 2023

CREATE OR REPLACE VIEW nova_vis_db.vis_schema.revenue_2024 AS
SELECT
    order_date::date AS order_date,
    total_price::number(10,2) AS total_price
FROM nova_db.nova_schema.fact_order
WHERE EXTRACT(YEAR FROM order_date::date) = 2024;

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

-----------------------------------------------------------------
------------------------------------------------------------
-- TOTAL REVENUE BY CUSTOMER SEGMENT
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
