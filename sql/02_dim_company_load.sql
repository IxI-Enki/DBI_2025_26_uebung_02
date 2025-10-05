----------------------------------------------------------------------------------------------------
-- Star Schema DIM loads for OT (Company)
-- Populates DIM_TIME, DIM_PRODUCT, DIM_CUSTOMER, DIM_EMPLOYEE, DIM_STATUS from OLTP
-- Idempotent: deletes and re-inserts all rows
-- Oracle SQL
----------------------------------------------------------------------------------------------------

-- Clear dimensions (safe if empty)
BEGIN EXECUTE IMMEDIATE 'DELETE FROM DIM_TIME';     EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DELETE FROM DIM_PRODUCT';  EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DELETE FROM DIM_CUSTOMER'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DELETE FROM DIM_EMPLOYEE'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DELETE FROM DIM_STATUS';   EXCEPTION WHEN OTHERS THEN NULL; END; /
COMMIT;

----------------------------------------------------------------------------------------------------
-- DIM_TIME from ORDERS.ORDER_DATE
----------------------------------------------------------------------------------------------------
INSERT INTO DIM_TIME (YEAR, MONTH, DAY)
SELECT
  EXTRACT(YEAR  FROM o.order_date) AS year,
  EXTRACT(MONTH FROM o.order_date) AS month,
  EXTRACT(DAY   FROM o.order_date) AS day
FROM (
  SELECT DISTINCT order_date FROM orders WHERE order_date IS NOT NULL
) o
ORDER BY 1;
COMMIT;

----------------------------------------------------------------------------------------------------
-- DIM_PRODUCT from PRODUCTS + PRODUCT_CATEGORIES (denormalized)
----------------------------------------------------------------------------------------------------
INSERT /*+ APPEND */ INTO DIM_PRODUCT (
  PRODUCT_NAME, CATEGORY_NAME, STANDARD_COST, LIST_PRICE, SOURCE_PRODUCT_ID
)
SELECT
  p.product_name,
  c.category_name,
  p.standard_cost,
  p.list_price,
  p.product_id
FROM products p
JOIN product_categories c ON c.category_id = p.category_id;
COMMIT;

----------------------------------------------------------------------------------------------------
-- DIM_CUSTOMER from CUSTOMERS
----------------------------------------------------------------------------------------------------
INSERT /*+ APPEND */ INTO DIM_CUSTOMER (
  CUSTOMER_NAME, ADDRESS, WEBSITE, CREDIT_LIMIT, SOURCE_CUSTOMER_ID
)
SELECT
  c.name,
  c.address,
  c.website,
  c.credit_limit,
  c.customer_id
FROM customers c;
COMMIT; 

----------------------------------------------------------------------------------------------------
-- DIM_EMPLOYEE from EMPLOYEES (salespersons)
----------------------------------------------------------------------------------------------------
INSERT /*+ APPEND */ INTO DIM_EMPLOYEE (
  FIRST_NAME, LAST_NAME, EMAIL, PHONE, HIRE_DATE, JOB_TITLE, SOURCE_EMPLOYEE_ID
)
SELECT
  e.first_name,
  e.last_name,
  e.email,
  e.phone,
  e.hire_date,
  e.job_title,
  e.employee_id
FROM employees e;
COMMIT; 

----------------------------------------------------------------------------------------------------
-- DIM_STATUS from ORDERS.STATUS
----------------------------------------------------------------------------------------------------
INSERT /*+ APPEND */ INTO DIM_STATUS (STATUS)
SELECT s.status
FROM (
  SELECT DISTINCT status FROM orders WHERE status IS NOT NULL
) s;
COMMIT; 
