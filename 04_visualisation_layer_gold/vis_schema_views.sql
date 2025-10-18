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
--3: CREATE GOLD VIEW TABLE FOR DELIVERY-------------
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


----------------------------------------------------
-- create view
-----------------------------------------------------

CREATE OR REPLACE VIEW V_DELIVERY_AREA AS
SELECT AVG(DELIVERY_TIME) AS AVG_TIME,
    CITY,
    STATE
FROM VIS_DELIVERY_SUMMARY
GROUP BY CITY, STATE;

--------------------------
CREATE OR REPLACE VIEW V_DELIVERY_SEASON AS
SELECT AVG(DELIVERY_TIME) AS AVG_TIME,
DELIVERY_MONTH,
DELIVERY_YEAR_LABEL
FROM VIS_DELIVERY_SUMMARY
GROUP BY DELIVERY_MONTH, DELIVERY_YEAR_LABEL;

