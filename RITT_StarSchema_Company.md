---
title: "RITT – Star-Schema Company (OT)"
author: "Jan Ritt"
github: "IxI-Enki"
course: "Datenbanken und Informationssysteme (DBI)"
school_year: "2025/26"
created: "2025-10-05"
assignment: "DBI Übung 02 – Star-Schema Company (OT)"
---

## Überblick

Diese Abgabe transformiert das OLTP-Schema der OT-Datenbank zu einem Star-Schema für den Analyse-Fokus "Sales" (Bestellungen und Positionen). Enthalten sind:

- DIMENSIONEN: `DIM_TIME`, `DIM_PRODUCT`, `DIM_CUSTOMER`, `DIM_EMPLOYEE`, `DIM_STATUS`
- FAKT: `FACT_SALES` (Grain: eine Zeile pro Bestellposition)
- DDL/DML-Skripte im Verzeichnis `sql/`
- Ausführungs-Skript `sql/assignment_run.sql`
- Visualisierungen (Mermaid-ER- und Star-Diagramme)

## Artefakte in diesem Repository

- `sql/01_dim_company_ddl.sql` – DDL für alle Dimensionen
- `sql/02_dim_company_load.sql` – Beladen der Dimensionen aus OLTP
- `sql/03_fact_sales_load.sql` – Erzeugen (falls fehlend) und Beladen der Faktentabelle
- `angabe/company_schema/ot_schema.sql` – OLTP-Ausgangsschema
- `angabe/company_schema/ot_data.sql` – Beispieldaten (OT)

## FACT_SALES

![Fact Sales](angabe/img/fact_sales.png)

---

## OLTP – relevante Entitäten (Ausschnitt)

```mermaid
erDiagram
  PRODUCT_CATEGORIES {
    NUMBER category_id PK
    VARCHAR2 category_name
  }

  PRODUCTS {
    NUMBER product_id PK
    VARCHAR2 product_name
    NUMBER category_id FK
    NUMBER standard_cost
    NUMBER list_price
  }

  CUSTOMERS {
    NUMBER customer_id PK
    VARCHAR2 name
    VARCHAR2 address
    VARCHAR2 website
    NUMBER credit_limit
  }

  EMPLOYEES {
    NUMBER employee_id PK
    VARCHAR2 first_name
    VARCHAR2 last_name
    VARCHAR2 email
    VARCHAR2 phone
    DATE hire_date
    VARCHAR2 job_title
  }

  ORDERS {
    NUMBER order_id PK
    NUMBER customer_id FK
    VARCHAR2 status
    NUMBER salesman_id FK
    DATE order_date
  }

  ORDER_ITEMS {
    NUMBER order_id FK
    NUMBER item_id
    NUMBER product_id FK
    NUMBER quantity
    NUMBER unit_price
  }

  PRODUCTS }o--|| PRODUCT_CATEGORIES : in
  ORDER_ITEMS }o--|| PRODUCTS : for
  ORDERS }o--|| CUSTOMERS : by
  ORDERS }o--|| EMPLOYEES : sold_by
  ORDER_ITEMS }o--|| ORDERS : contains
```

---

## Star-Schema – Zielmodell

```mermaid
erDiagram
  DIM_TIME {
    NUMBER id PK
    NUMBER year
    NUMBER month
    NUMBER day
  }

  DIM_PRODUCT {
    NUMBER id PK
    VARCHAR2 product_name
    VARCHAR2 category_name
    NUMBER standard_cost
    NUMBER list_price
    NUMBER source_product_id
  }

  DIM_CUSTOMER {
    NUMBER id PK
    VARCHAR2 customer_name
    VARCHAR2 address
    VARCHAR2 website
    NUMBER credit_limit
    NUMBER source_customer_id
  }

  DIM_EMPLOYEE {
    NUMBER id PK
    VARCHAR2 first_name
    VARCHAR2 last_name
    VARCHAR2 email
    VARCHAR2 phone
    DATE hire_date
    VARCHAR2 job_title
    NUMBER source_employee_id
  }

  DIM_STATUS {
    NUMBER id PK
    VARCHAR2 status
  }

  FACT_SALES {
    NUMBER t FK
    NUMBER product FK
    NUMBER customer FK
    NUMBER employee FK
    NUMBER status FK
    NUMBER order_id
    NUMBER item_id
    NUMBER quantity
    NUMBER unit_price
    NUMBER amount
  }

  FACT_SALES }o--|| DIM_TIME : t
  FACT_SALES }o--|| DIM_PRODUCT : product
  FACT_SALES }o--|| DIM_CUSTOMER : customer
  FACT_SALES }o--o| DIM_EMPLOYEE : employee
  FACT_SALES }o--|| DIM_STATUS : status
```

Erläuterungen:

- Grain: eine Zeile pro Bestellposition (`order_id`, `item_id`).
- Measures: `quantity`, `unit_price`, `amount = quantity * unit_price`.
- Degenerierter Schlüssel: `order_id`, `item_id` liegen in der Faktentabelle für Lineage/Drill-Through.
- `employee` kann `NULL` sein (wenn `salesman_id` leer war);
  in Analysen kann optional ein "Unbekannt"-Mitglied ergänzt werden.

---

## Ausführungsreihenfolge

1. OLTP-OT-Schema bereitstellen (`angabe/company_schema/ot_schema.sql` + Daten)
2. Star-Schema erzeugen und befüllen:
   - `@sql/assignment_run.sql`

Die Skripte sind idempotent (löschen vor Neu-Ladung bzw. `CREATE IF MISSING`).

---

## Kurze technische Notizen

- Dimensionen nutzen Surrogat-Schlüssel via IDENTITY-Spalten (keine Sequenzen notwendig).
- `DIM_PRODUCT` denormalisiert die Kategorie.
- Zeitdimension wird aus `orders.order_date` generiert.
- Faktbeladung löst alle Schlüssel deterministisch über `SOURCE_*_ID` bzw. Status-Text und Datum auf.
