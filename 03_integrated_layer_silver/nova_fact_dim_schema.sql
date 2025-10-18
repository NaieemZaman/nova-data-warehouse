--CREATE TABLE DIM_DELIVERY –
– This table contains information about delivery for each order
– including information extracted from the raw_delivery table
– Data cleaning techniques:
----- - use TO_DATE and DATEDIFF to extract the date
----- - use SPLIT_PART to extract the address
-----------------------------------------------

USE DATABASE NOVA_DB;
USE SCHEMA NOVA_SCHEMA;
CREATE OR REPLACE TABLE DIM_DELIVERY AS
    SELECT RD.DELIVERY_ID,
    MONTH(TO_DATE(DATE_OF_DELIVERY, 'DD/MM/YYYY')) AS DELIVERY_MONTH,
    YEAR(TO_DATE(DATE_OF_DELIVERY, 'DD/MM/YYYY')) AS DELIVERY_YEAR,
    MONTH(TO_DATE(DATE_OF_ARRIVAL, 'DD/MM/YYYY')) AS ARRIVAL_MONTH,
    YEAR(TO_DATE(DATE_OF_ARRIVAL, 'DD/MM/YYYY')) AS ARRIVAL_YEAR,
    DATEDIFF (
    'day',
    TO_DATE(RD.DATE_OF_DELIVERY, 'DD/MM/YYYY'),
    TO_DATE(RD.DATE_OF_ARRIVAL, 'DD/MM/YYYY')
    ) AS DELIVERY_TIME_DAYS,
    TRIM(SPLIT_PART(RO.ADDRESS, ',', 2)) AS city,
    TRIM(SPLIT_PART(RO.ADDRESS, ',', 3)) AS STATE
FROM NOVA_RAW_DB.LSP_RAW_SCHEMA.RAW_DELIVERY RD
JOIN NOVA_RAW_DB.OMS_RAW_SCHEMA.RAW_ORDER RO
ON RD.DELIVERY_ID = RO.DELIVERY_ID;

ALTER TABLE DIM_DELIVERY 
ADD PRIMARY KEY (DELIVERY_ID);

ALTER TABLE DIM_DELIVERY ADD COLUMN DELIVERY_YEAR_LABEL VARCHAR;

UPDATE DIM_DELIVERY
SET DELIVERY_YEAR_LABEL = TO_VARCHAR(DELIVERY_YEAR);



-- ===============================================================
-- TABLE: DIM_CUSTOMER

-- This table contains unique customer records extracted from the raw_order table.
-- Basic data cleansing is applied: duplicates are removed using SELECT DISTINCT.
-- Data types are preserved as STRING for simplicity and to support flexible joins.
-- ===============================================================

CREATE OR REPLACE TABLE dim_customer (
    customer_id STRING NOT NULL PRIMARY KEY,        -- Unique identifier for each customer
    cus_name STRING,                                -- Full name of the customer
    phone STRING,                                   -- Phone number of the customer
    email STRING                                    -- Email address of the customer
);

-- Load unique customer records from raw_order into dim_customer
INSERT INTO nova_db.nova_schema.dim_customer (customer_id, cus_name, phone, email)
SELECT DISTINCT
    customer_id,
    cus_name,
    phone,
    email
FROM nova_raw_db.oms_raw_schema.raw_order;
-- DIM_PRODUCT

CREATE OR REPLACE TABLE NOVA_DB.NOVA_SCHEMA.DIM_PRODUCT AS
SELECT 
    PRODUCT_ID::STRING AS PRODUCT_ID,
    QUANTITY::NUMBER AS QUANTITY,
    PRODUCT_NAME::STRING AS PRODUCT_NAME,
    PRICE::NUMBER(10,2) AS PRICE,
FROM RAW_PRODUCT;

ALTER TABLE NOVA_DB.NOVA_SCHEMA.DIM_PRODUCT
ADD CONSTRAINT PK_DIM_PRODUCT PRIMARY KEY (PRODUCT_ID);

-- ===============================================================
-- TABLE: FACT_ORDER

-- This fact table contains cleaned order transaction data.
-- It includes foreign key references to relevant dimension tables:
--     - dim_customer
--     - dim_product
--     - dim_delivery
-- The raw data is type-cast appropriately for analysis and aggregation.
-- ===============================================================

CREATE OR REPLACE TABLE fact_order (
    order_id STRING NOT NULL PRIMARY KEY,           -- Unique identifier for each order
    order_date DATE,                                -- Order date converted from STRING to DATE
    customer_id STRING,                             -- Foreign key reference to dim_customer
    product_id STRING,                              -- Foreign key reference to dim_product
    delivery_id STRING,                             -- Foreign key reference to dim_delivery
    order_quantity INT,                             -- Quantity of products ordered (converted to INT)
    total_price NUMBER(10,2),                       -- Total price of the order (converted to decimal)
    
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (delivery_id) REFERENCES dim_delivery(delivery_id)
);


-- Load cleaned order records from raw_order into fact_order
-- Includes:
--     - Type casting for order_date, quantity, and total_price
--     - Deduplication using SELECT DISTINCT
INSERT INTO nova_db.nova_schema.fact_order (customer_id, delivery_id, order_date, order_id, order_quantity, product_id, total_price)
SELECT
    DISTINCT customer_id,
    delivery_id,
    TO_DATE(order_date, 'DD/MM/YYYY') AS order_date,    -- Convert string to DATE format
    order_id,
    CAST(quantity AS INT),                              -- Convert quantity to INT
    product_id,
    CAST(total_price AS NUMBER(10,2)),                  -- Convert total_price to decimal with 2 digits
FROM nova_raw_db.oms_raw_schema.raw_order;




