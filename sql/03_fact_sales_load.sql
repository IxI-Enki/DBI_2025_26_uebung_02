----------------------------------------------------------------------------------------------------
-- FACT_SALES create and load for OT (Company)
-- Grain: one row per order line (order_id, item_id)
-- Dimensions: TIME, PRODUCT, CUSTOMER, EMPLOYEE (nullable), STATUS
-- Measures: quantity, unit_price, amount (quantity * unit_price)
-- Idempotent: deletes before re-insert
-- Oracle SQL
----------------------------------------------------------------------------------------------------

-- Drop and recreate FACT_SALES to ensure deterministic DDL
BEGIN EXECUTE IMMEDIATE 'DROP TABLE FACT_SALES CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /

CREATE TABLE FACT_SALES (
  t          NUMBER       NOT NULL REFERENCES DIM_TIME(id),
  product    NUMBER       NOT NULL REFERENCES DIM_PRODUCT(id),
  customer   NUMBER       NOT NULL REFERENCES DIM_CUSTOMER(id),
  employee   NUMBER           NULL REFERENCES DIM_EMPLOYEE(id),
  status     NUMBER       NOT NULL REFERENCES DIM_STATUS(id),
  order_id   NUMBER       NOT NULL,
  item_id    NUMBER       NOT NULL,
  quantity   NUMBER(8,2)  NOT NULL,
  unit_price NUMBER(8,2)  NOT NULL,
  amount     NUMBER(12,2) NOT NULL,
  CONSTRAINT PK_FACT_SALES PRIMARY KEY (t, product, customer, status, order_id, item_id)
);


-- Idempotent load
BEGIN EXECUTE IMMEDIATE 'DELETE FROM FACT_SALES'; EXCEPTION WHEN OTHERS THEN NULL; END; /
COMMIT;

INSERT /*+ APPEND */ INTO FACT_SALES (
  t, product, customer, employee, status, order_id, item_id, quantity, unit_price, amount
)
SELECT
  tm.id                                              AS t,
  dp.id                                              AS product,
  dc.id                                              AS customer,
  de.id                                              AS employee,
  ds.id                                              AS status,
  o.order_id,
  oi.item_id,
  oi.quantity,
  oi.unit_price,
  (oi.quantity * oi.unit_price)                      AS amount
FROM orders o
JOIN order_items oi       ON oi.order_id = o.order_id
JOIN products p           ON p.product_id = oi.product_id
JOIN DIM_PRODUCT  dp      ON dp.SOURCE_PRODUCT_ID = p.product_id
JOIN DIM_CUSTOMER dc      ON dc.SOURCE_CUSTOMER_ID = o.customer_id
LEFT JOIN DIM_EMPLOYEE de ON de.SOURCE_EMPLOYEE_ID = o.salesman_id
JOIN DIM_STATUS ds        ON ds.STATUS = o.status
JOIN (
  SELECT year, month, day, MIN(id) AS id
  FROM DIM_TIME
  GROUP BY year, month, day
) tm
  ON tm.year  = EXTRACT(YEAR  FROM o.order_date)
 AND tm.month = EXTRACT(MONTH FROM o.order_date)
 AND tm.day   = EXTRACT(DAY   FROM o.order_date);

COMMIT;
