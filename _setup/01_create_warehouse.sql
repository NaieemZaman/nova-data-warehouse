-- STEP 1: CREATE WAREHOUSE (Virtual Compute Resource)
-- ------------------------------------------------------------
-- This warehouse handles the compute for all SQL operations.
-- 'XSmall' is cost-effective for development/testing.
-- 'INITIALLY_SUSPENDED = TRUE' ensures the warehouse is off by default to save credits.

CREATE OR REPLACE WAREHOUSE NOVA_WH
    WITH WAREHOUSE_SIZE = XSmall 
    INITIALLY_SUSPENDED = TRUE;

-- Activate the warehouse for current session
USE WAREHOUSE NOVA_WH;
