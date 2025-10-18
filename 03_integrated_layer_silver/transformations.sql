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

DIM_PRODUCT

CREATE OR REPLACE TABLE NOVA_DB.NOVA_SCHEMA.DIM_PRODUCT AS
SELECT 
    PRODUCT_ID::STRING AS PRODUCT_ID,
    QUANTITY::NUMBER AS QUANTITY,
    PRODUCT_NAME::STRING AS PRODUCT_NAME,
    PRICE::NUMBER(10,2) AS PRICE,
FROM RAW_PRODUCT;

ALTER TABLE NOVA_DB.NOVA_SCHEMA.DIM_PRODUCT
ADD CONSTRAINT PK_DIM_PRODUCT PRIMARY KEY (PRODUCT_ID);


