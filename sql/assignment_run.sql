----------------------------------------------------------------------------------------------------
-- Assignment Runner: STAR SCHEMA COMPANY (OT)
-- DBI - Datenbanken und Informationssysteme
-- HTL Leonding
-- Author: Jan Ritt
-- Date: 2025-10-05
--
-- Purpose: Orchestrates Star Schema creation and loading in 3 steps
--   1) Create dimension tables (DDL)
--   2) Load dimensions (DML)
--   3) Create and load FACT_SALES
--
-- Usage (SQL*Plus or compatible):
--   @sql/assignment_run.sql
----------------------------------------------------------------------------------------------------

PROMPT === Step 1/3: Create Dimensions (DDL) ===
@sql/01_dim_company_ddl.sql

PROMPT === Step 2/3: Load Dimensions (DML) ===
@sql/02_dim_company_load.sql

PROMPT === Step 3/3: Create + Load FACT_SALES ===
@sql/03_fact_sales_load.sql

PROMPT === DONE ===

SELECT * FROM FACT_SALES;