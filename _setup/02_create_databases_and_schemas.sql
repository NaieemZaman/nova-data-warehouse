-- STEP 2: CREATE RAW DATA DATABASE (Bronze Layer)
-- ------------------------------------------------------------
-- This database stores raw, unprocessed data from source systems.

CREATE OR REPLACE DATABASE NOVA_RAW_DB;
USE DATABASE NOVA_RAW_DB;

-- Create schemas for each source system
-- OMS = Order Management System
-- WMS = Warehouse Management System
-- LSP = Logistics/Shipping Provider

CREATE OR REPLACE SCHEMA LSP_RAW_SCHEMA;
CREATE OR REPLACE SCHEMA OMS_RAW_SCHEMA;
CREATE OR REPLACE SCHEMA WMS_RAW_SCHEMA;

-- ------------------------------------------------------------
-- STEP 3: CREATE INTEGRATED DATA WAREHOUSE (Silver Layer)
-- ------------------------------------------------------------
-- This database stores cleaned and structured data in star schema format.
-- Fact and Dimension tables are modeled here, after transformation from raw tables.

CREATE OR REPLACE DATABASE NOVA_DB;
USE DATABASE NOVA_DB;

-- Create schema to hold fact and dimension tables
CREATE OR REPLACE SCHEMA NOVA_SCHEMA;

-- ------------------------------------------------------------
-- STEP 4: CREATE VISUALISATION DATABASE (Gold Layer)
-- ------------------------------------------------------------
-- This database stores reporting-focused tables and views.
-- These may include summaries, filters, or subsets of fact/dim tables
-- used to answer business questions and support dashboards.

CREATE OR REPLACE DATABASE NOVA_VIS_DB;
USE DATABASE NOVA_VIS_DB;

-- Schema for business reporting views and tables
CREATE SCHEMA VIS_SCHEMA;




