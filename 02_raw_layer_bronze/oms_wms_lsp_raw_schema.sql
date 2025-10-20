-- This RAW table is part of the Bronze Layer in the data pipeline.
-- All columns are defined as STRING to safely ingest raw source data without applying transformations or enforcing data types.
-- Using STRING avoids load-time errors due to inconsistent or malformed values (e.g., unexpected text in numeric fields).
-- Data cleansing, type casting, and enrichment will be performed later in the Silver Layer.

-- ===============================================================
-- TABLE: RAW_ORDER
-- Stores raw order transactions from the Order Management System (OMS)
-- ===============================================================

CREATE OR REPLACE TABLE NOVA_RAW_DB.OMS_RAW_SCHEMA.RAW_ORDER (
    order_id STRING,            -- Unique identifier for each order
    order_date STRING,          -- Date when the order was placed
    delivery_id STRING,         -- Reference to delivery record
    product_id STRING,          -- Reference to the purchased product
    customer_id STRING,         -- Reference to the customer placing the order
    cus_name STRING,            -- Customer’s full name
    quantity STRING,            -- Quantity of product ordered
    total_price STRING,         -- Total amount paid for the order
    phone STRING,               -- Customer’s phone number
    email STRING,               -- Customer’s email address
    address STRING              -- Delivery address
);

-- ===============================================================
-- TABLE: RAW_DELIVERY
-- Stores raw delivery data from the Logistics Service Provider (LSP)
-- ===============================================================

CREATE OR REPLACE TABLE NOVA_RAW_DB.LSP_RAW_SCHEMA.RAW_DELIVERY (
    delivery_id STRING,         -- Unique identifier for the delivery
    date_of_delivery STRING,    -- Date the item was shipped out
    date_of_arrival STRING,     -- Date the item arrived or is expected
    status STRING,              -- Delivery status (e.g., shipped, failed)
    product_id STRING           -- Reference to the product being delivered
);

-- ===============================================================
-- LOAD RAW_ORDER FROM STAGE INTO BRONZE TABLE
-- Source file: nova_order.csv located in internal stage @raw_stage
-- ===============================================================

COPY INTO NOVA_RAW_DB.OMS_RAW_SCHEMA.RAW_ORDER
FROM @raw_stage/raw_order.csv
FILE_FORMAT = (
    TYPE = 'CSV',                           -- File is in CSV format
    SKIP_HEADER = 1,                        -- Skip the first row (column headers)
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'      -- Fields optionally enclosed by double quotes
)
ON_ERROR = 'CONTINUE';                      -- Skip and continue on bad rows (data quality issue)

-- ===============================================================
-- LOAD RAW_DELIVERY FROM STAGE INTO BRONZE TABLE
-- Source file: raw_shipment.csv located in internal stage @raw_stage
-- ===============================================================

COPY INTO NOVA_RAW_DB.LSP_RAW_SCHEMA.RAW_DELIVERY
FROM @raw_stage/raw_delivery.csv
FILE_FORMAT = (
    TYPE = 'CSV',
    SKIP_HEADER = 1,
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
)
ON_ERROR = 'CONTINUE';



-- RAW_PRODUCT table

USE ROLE NOVA_ROLE;
CREATE WAREHOUSE IF NOT EXISTS NOVA_WH INITIALLY_SUSPENDED=TRUE;
USE WAREHOUSE NOVA_WH;
USE SCHEMA NOVA_RAW_DB.WMS_RAW_SCHEMA;



CREATE OR REPLACE TABLE RAW_PRODUCT(
PRODUCT_ID VARCHAR,
QUANTITY NUMBER,
PRODUCT_NAME VARCHAR,
PRICE NUMBER(10,2),
DESCRIPTION VARCHAR,
CATEGORY VARCHAR
);




