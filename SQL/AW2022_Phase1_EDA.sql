/* ============================================================
   AdventureWorks 2022 – Phase 1: Schema Exploration
   Tool  : SQL Server Management Studio (SSMS)
   Output: Views ready for Power BI Direct Query / Import
   ============================================================

   EXECUTION ORDER
   ---------------
   1. Run Section 1  – Health checks  (results only, no objects created)
   2. Run Section 2  – Create all EDA views
   3. Connect Power BI → Import each view as a separate table
   ============================================================ */

USE AdventureWorks2022;
GO

/* ============================================================
   SECTION 1 – HEALTH CHECKS
   Run these ad-hoc in SSMS to understand the database before
   building views. They produce result sets, not objects.
   ============================================================ */

-- ── 1.1  All schemas and table counts ─────────────────────────
SELECT
    s.name                          AS schema_name,
    COUNT(t.object_id)              AS table_count
FROM sys.schemas  s
JOIN sys.tables   t ON t.schema_id = s.schema_id
GROUP BY s.name
ORDER BY table_count DESC;
GO

-- ── 1.2  Row counts for every table in the database ───────────
SELECT
    s.name                          AS schema_name,
    t.name                          AS table_name,
    p.rows                          AS row_count
FROM sys.tables          t
JOIN sys.schemas         s  ON s.schema_id  = t.schema_id
JOIN sys.partitions      p  ON p.object_id  = t.object_id
                           AND p.index_id  IN (0, 1)
ORDER BY p.rows DESC;
GO

-- ── 1.3  Column inventory for key tables ──────────────────────
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    ORDINAL_POSITION,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA IN ('Sales','Production','Purchasing','HumanResources','Person')
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;
GO

-- ── 1.4  NULL % audit for SalesOrderHeader ────────────────────
SELECT
    'SalesOrderHeader'                                   AS table_name,
    COUNT(*)                                             AS total_rows,
    SUM(CASE WHEN PurchaseOrderNumber IS NULL THEN 1 ELSE 0 END)   AS null_PONumber,
    SUM(CASE WHEN AccountNumber       IS NULL THEN 1 ELSE 0 END)   AS null_AccountNumber,
    SUM(CASE WHEN ShipDate            IS NULL THEN 1 ELSE 0 END)   AS null_ShipDate,
    SUM(CASE WHEN CreditCardID        IS NULL THEN 1 ELSE 0 END)   AS null_CreditCardID,
    SUM(CASE WHEN SalesPersonID       IS NULL THEN 1 ELSE 0 END)   AS null_SalesPersonID,
    SUM(CASE WHEN TerritoryID         IS NULL THEN 1 ELSE 0 END)   AS null_TerritoryID,
    SUM(CASE WHEN CurrencyRateID      IS NULL THEN 1 ELSE 0 END)   AS null_CurrencyRateID
FROM Sales.SalesOrderHeader;
GO

-- ── 1.5  Duplicate check on natural keys ──────────────────────
-- Products with duplicate ProductNumber
SELECT ProductNumber, COUNT(*) AS cnt
FROM Production.Product
GROUP BY ProductNumber
HAVING COUNT(*) > 1;

-- Customers with duplicate AccountNumber
SELECT AccountNumber, COUNT(*) AS cnt
FROM Sales.Customer
GROUP BY AccountNumber
HAVING COUNT(*) > 1;
GO

-- ── 1.6  Date range audit ─────────────────────────────────────
SELECT
    MIN(OrderDate)   AS earliest_order,
    MAX(OrderDate)   AS latest_order,
    DATEDIFF(MONTH, MIN(OrderDate), MAX(OrderDate))   AS months_span,
    COUNT(DISTINCT YEAR(OrderDate))                   AS distinct_years
FROM Sales.SalesOrderHeader;
GO

-- ── 1.7  Online vs offline split ──────────────────────────────
SELECT
    OnlineOrderFlag,
    COUNT(*)                  AS order_count,
    ROUND(SUM(TotalDue),2)    AS total_revenue,
    ROUND(AVG(TotalDue),2)    AS avg_order_value
FROM Sales.SalesOrderHeader
GROUP BY OnlineOrderFlag;
GO


/* ============================================================
   SECTION 2 – CREATE EDA VIEWS FOR POWER BI
   All views live in a dedicated schema: [eda]
   ============================================================ */

-- Create the EDA schema if it doesn't exist
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'eda')
    EXEC('CREATE SCHEMA eda');
GO

/* ────────────────────────────────────────────────────────────
   VIEW 1 – eda.vw_SalesOverview
   Power BI usage : KPI cards, line chart (revenue over time),
                    bar chart (online vs offline)
   ──────────────────────────────────────────────────────────── */
CREATE OR ALTER VIEW eda.vw_SalesOverview AS
SELECT
    soh.SalesOrderID,
    soh.OrderDate,
    YEAR(soh.OrderDate)                                          AS order_year,
    MONTH(soh.OrderDate)                                         AS order_month,
    DATENAME(MONTH, soh.OrderDate)                               AS order_month_name,
    CAST(DATEFROMPARTS(YEAR(soh.OrderDate),
                       MONTH(soh.OrderDate), 1) AS DATE)         AS order_month_key,   -- for time axis
    soh.DueDate,
    soh.ShipDate,
    DATEDIFF(DAY, soh.OrderDate, soh.ShipDate)                   AS days_to_ship,
    soh.Status,
    CASE soh.Status
        WHEN 1 THEN 'In Process'
        WHEN 2 THEN 'Approved'
        WHEN 3 THEN 'Backordered'
        WHEN 4 THEN 'Rejected'
        WHEN 5 THEN 'Shipped'
        WHEN 6 THEN 'Cancelled'
        ELSE 'Unknown'
    END                                                          AS status_label,
    soh.OnlineOrderFlag,
    CASE soh.OnlineOrderFlag WHEN 1 THEN 'Online' ELSE 'Sales Rep' END AS order_channel,
    soh.SalesPersonID,
    soh.TerritoryID,
    st.Name                                                      AS territory_name,
    st.[Group]                                                   AS territory_group,
    st.CountryRegionCode,
    soh.SubTotal,
    soh.TaxAmt,
    soh.Freight,
    soh.TotalDue,
    soh.CurrencyRateID,
    ISNULL(cr.AverageRate, 1)                                    AS exchange_rate_to_USD
FROM Sales.SalesOrderHeader            soh
LEFT JOIN Sales.SalesTerritory         st  ON st.TerritoryID    = soh.TerritoryID
LEFT JOIN Sales.CurrencyRate           cr  ON cr.CurrencyRateID = soh.CurrencyRateID;
GO

/* ────────────────────────────────────────────────────────────
   VIEW 2 – eda.vw_SalesLineItems
   Power BI usage : product performance table, margin bar chart,
                    quantity distribution histogram
   ──────────────────────────────────────────────────────────── */
CREATE OR ALTER VIEW eda.vw_SalesLineItems AS
SELECT
    sod.SalesOrderID,
    sod.SalesOrderDetailID,
    soh.OrderDate,
    YEAR(soh.OrderDate)                                          AS order_year,
    MONTH(soh.OrderDate)                                         AS order_month,
    sod.ProductID,
    p.Name                                                       AS product_name,
    p.ProductNumber,
    p.Color,
    p.Size,
    p.Weight,
    p.StandardCost,
    p.ListPrice,
    ISNULL(psc.Name, 'N/A')                                      AS subcategory_name,
    ISNULL(pc.Name,  'N/A')                                      AS category_name,
    sod.OrderQty,
    sod.UnitPrice,
    sod.UnitPriceDiscount,
    sod.LineTotal,
    -- Derived metrics
    ROUND(sod.UnitPrice - p.StandardCost, 2)                     AS unit_margin,
    CASE WHEN sod.UnitPrice > 0
         THEN ROUND((sod.UnitPrice - p.StandardCost) / sod.UnitPrice * 100, 2)
         ELSE 0
    END                                                          AS margin_pct,
    ROUND(sod.UnitPriceDiscount * 100, 2)                        AS discount_pct,
    sod.OrderQty * p.StandardCost                                AS total_cost,
    sod.LineTotal - (sod.OrderQty * p.StandardCost)              AS gross_profit
FROM Sales.SalesOrderDetail            sod
JOIN Sales.SalesOrderHeader            soh ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product                p   ON p.ProductID      = sod.ProductID
LEFT JOIN Production.ProductSubcategory psc ON psc.ProductSubcategoryID = p.ProductSubcategoryID
LEFT JOIN Production.ProductCategory   pc  ON pc.ProductCategoryID      = psc.ProductCategoryID;
GO

/* ────────────────────────────────────────────────────────────
   VIEW 3 – eda.vw_CustomerProfile
   Power BI usage : customer count KPI, map by territory,
                    individual vs store donut chart
   ──────────────────────────────────────────────────────────── */
CREATE OR ALTER VIEW eda.vw_CustomerProfile AS
SELECT
    c.CustomerID,
    CASE
        WHEN c.PersonID  IS NOT NULL AND c.StoreID IS NULL THEN 'Individual'
        WHEN c.StoreID   IS NOT NULL                       THEN 'Store'
        ELSE 'Unknown'
    END                                                          AS customer_type,
    c.AccountNumber,
    c.TerritoryID,
    st.Name                                                      AS territory_name,
    st.[Group]                                                   AS territory_group,
    st.CountryRegionCode,
    -- Person details (individual customers)
    ISNULL(pp.FirstName + ' ' + pp.LastName, s.Name)             AS customer_name,
    pp.EmailPromotion,
    -- Aggregated order history
    ord.total_orders,
    ord.first_order_date,
    ord.last_order_date,
    DATEDIFF(DAY, ord.first_order_date, ord.last_order_date)     AS customer_tenure_days,
    ord.lifetime_value,
    ROUND(ord.lifetime_value / NULLIF(ord.total_orders, 0), 2)   AS avg_order_value
FROM Sales.Customer                    c
LEFT JOIN Person.Person                pp  ON pp.BusinessEntityID = c.PersonID
LEFT JOIN Sales.Store                  s   ON s.BusinessEntityID  = c.StoreID
LEFT JOIN Sales.SalesTerritory         st  ON st.TerritoryID      = c.TerritoryID
LEFT JOIN (
    SELECT
        CustomerID,
        COUNT(*)            AS total_orders,
        MIN(OrderDate)      AS first_order_date,
        MAX(OrderDate)      AS last_order_date,
        ROUND(SUM(TotalDue),2) AS lifetime_value
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
) ord ON ord.CustomerID = c.CustomerID;
GO

/* ────────────────────────────────────────────────────────────
   VIEW 4 – eda.vw_ProductCatalog
   Power BI usage : product table slicer, price vs cost scatter,
                    inventory level gauge
   ──────────────────────────────────────────────────────────── */
CREATE OR ALTER VIEW eda.vw_ProductCatalog AS
SELECT
    p.ProductID,
    p.ProductNumber,
    p.Name                                                       AS product_name,
    p.Color,
    p.Size,
    p.SizeUnitMeasureCode,
    p.Weight,
    p.WeightUnitMeasureCode,
    p.StandardCost,
    p.ListPrice,
    ROUND(p.ListPrice - p.StandardCost, 2)                       AS unit_margin,
    CASE WHEN p.ListPrice > 0
         THEN ROUND((p.ListPrice - p.StandardCost) / p.ListPrice * 100, 2)
         ELSE 0
    END                                                          AS margin_pct,
    p.SafetyStockLevel,
    p.ReorderPoint,
    p.DaysToManufacture,
    p.SellStartDate,
    p.SellEndDate,
    p.DiscontinuedDate,
    CASE WHEN p.DiscontinuedDate IS NOT NULL THEN 'Discontinued'
         WHEN p.SellEndDate       IS NOT NULL AND p.SellEndDate < GETDATE() THEN 'Expired'
         ELSE 'Active'
    END                                                          AS product_status,
    ISNULL(psc.Name, 'N/A')                                      AS subcategory_name,
    ISNULL(pc.Name,  'N/A')                                      AS category_name,
    pm.Name                                                      AS product_model,
    -- Current inventory
    ISNULL(inv.total_qty_on_hand, 0)                             AS qty_on_hand
FROM Production.Product                p
LEFT JOIN Production.ProductSubcategory psc ON psc.ProductSubcategoryID = p.ProductSubcategoryID
LEFT JOIN Production.ProductCategory   pc  ON pc.ProductCategoryID      = psc.ProductCategoryID
LEFT JOIN Production.ProductModel      pm  ON pm.ProductModelID         = p.ProductModelID
LEFT JOIN (
    SELECT ProductID, SUM(Quantity) AS total_qty_on_hand
    FROM Production.ProductInventory
    GROUP BY ProductID
) inv ON inv.ProductID = p.ProductID;
GO

/* ────────────────────────────────────────────────────────────
   VIEW 5 – eda.vw_EmployeeProfile
   Power BI usage : headcount KPI, gender/marital donut,
                    department bar chart, tenure histogram
   ──────────────────────────────────────────────────────────── */
CREATE OR ALTER VIEW eda.vw_EmployeeProfile AS
SELECT
    e.BusinessEntityID                                           AS employee_id,
    pp.FirstName + ' ' + pp.LastName                             AS employee_name,
    e.JobTitle,
    e.Gender,
    e.MaritalStatus,
    CASE e.MaritalStatus WHEN 'M' THEN 'Married' ELSE 'Single' END AS marital_label,
    e.HireDate,
    DATEDIFF(YEAR, e.HireDate, GETDATE())                        AS tenure_years,
    e.SalariedFlag,
    CASE e.SalariedFlag WHEN 1 THEN 'Salaried' ELSE 'Hourly' END AS pay_type,
    e.VacationHours,
    e.SickLeaveHours,
    dept.Name                                                    AS department_name,
    dept.GroupName                                               AS department_group,
    edh.StartDate                                                AS dept_start_date,
    -- Latest pay rate
    eph.Rate                                                     AS current_rate,
    eph.PayFrequency
FROM HumanResources.Employee                   e
JOIN Person.Person                             pp   ON pp.BusinessEntityID  = e.BusinessEntityID
LEFT JOIN HumanResources.EmployeeDepartmentHistory edh
    ON edh.BusinessEntityID = e.BusinessEntityID
    AND edh.EndDate IS NULL
LEFT JOIN HumanResources.Department            dept ON dept.DepartmentID    = edh.DepartmentID
LEFT JOIN (
    SELECT BusinessEntityID, Rate, PayFrequency,
           ROW_NUMBER() OVER (PARTITION BY BusinessEntityID ORDER BY RateChangeDate DESC) AS rn
    FROM HumanResources.EmployeePayHistory
) eph ON eph.BusinessEntityID = e.BusinessEntityID AND eph.rn = 1;
GO

/* ────────────────────────────────────────────────────────────
   VIEW 6 – eda.vw_PurchasingOverview
   Power BI usage : vendor count KPI, PO value bar, lead time box
   ──────────────────────────────────────────────────────────── */
CREATE OR ALTER VIEW eda.vw_PurchasingOverview AS
SELECT
    poh.PurchaseOrderID,
    poh.OrderDate,
    YEAR(poh.OrderDate)                                          AS order_year,
    MONTH(poh.OrderDate)                                         AS order_month,
    poh.Status,
    CASE poh.Status
        WHEN 1 THEN 'Pending'
        WHEN 2 THEN 'Approved'
        WHEN 3 THEN 'Rejected'
        WHEN 4 THEN 'Complete'
        ELSE 'Unknown'
    END                                                          AS status_label,
    poh.VendorID,
    v.Name                                                       AS vendor_name,
    v.CreditRating,
    v.PreferredVendorStatus,
    poh.EmployeeID,
    poh.ShipMethodID,
    sm.Name                                                      AS ship_method,
    poh.SubTotal,
    poh.TaxAmt,
    poh.Freight,
    poh.TotalDue,
    -- Derived
    DATEDIFF(DAY, poh.OrderDate, poh.ShipDate)                   AS lead_time_days,
    line_agg.line_count,
    line_agg.total_qty_ordered
FROM Purchasing.PurchaseOrderHeader            poh
JOIN Purchasing.Vendor                         v   ON v.BusinessEntityID = poh.VendorID
LEFT JOIN Purchasing.ShipMethod                sm  ON sm.ShipMethodID    = poh.ShipMethodID
LEFT JOIN (
    SELECT PurchaseOrderID,
           COUNT(*)          AS line_count,
           SUM(OrderQty)     AS total_qty_ordered
    FROM Purchasing.PurchaseOrderDetail
    GROUP BY PurchaseOrderID
) line_agg ON line_agg.PurchaseOrderID = poh.PurchaseOrderID;
GO

/* ────────────────────────────────────────────────────────────
   VIEW 7 – eda.vw_DataHealthSummary
   Power BI usage : data quality table — one row per key table
                    showing nulls, dupes, row counts
   ──────────────────────────────────────────────────────────── */
CREATE OR ALTER VIEW eda.vw_DataHealthSummary AS

-- Sales.SalesOrderHeader
SELECT
    'Sales.SalesOrderHeader'                             AS table_name,
    COUNT(*)                                             AS total_rows,
    SUM(CASE WHEN SalesPersonID       IS NULL THEN 1 ELSE 0 END) AS null_count_col1,
    'SalesPersonID'                                      AS null_col1_name,
    SUM(CASE WHEN ShipDate            IS NULL THEN 1 ELSE 0 END) AS null_count_col2,
    'ShipDate'                                           AS null_col2_name,
    SUM(CASE WHEN CreditCardID        IS NULL THEN 1 ELSE 0 END) AS null_count_col3,
    'CreditCardID'                                       AS null_col3_name,
    COUNT(DISTINCT SalesOrderID)                         AS distinct_pk_count
FROM Sales.SalesOrderHeader

UNION ALL

-- Sales.SalesOrderDetail
SELECT
    'Sales.SalesOrderDetail',
    COUNT(*),
    SUM(CASE WHEN CarrierTrackingNumber IS NULL THEN 1 ELSE 0 END),
    'CarrierTrackingNumber',
    0, 'N/A',
    0, 'N/A',
    COUNT(DISTINCT SalesOrderDetailID)
FROM Sales.SalesOrderDetail

UNION ALL

-- Sales.Customer
SELECT
    'Sales.Customer',
    COUNT(*),
    SUM(CASE WHEN PersonID  IS NULL THEN 1 ELSE 0 END),
    'PersonID',
    SUM(CASE WHEN StoreID   IS NULL THEN 1 ELSE 0 END),
    'StoreID',
    SUM(CASE WHEN TerritoryID IS NULL THEN 1 ELSE 0 END),
    'TerritoryID',
    COUNT(DISTINCT CustomerID)
FROM Sales.Customer

UNION ALL

-- Production.Product
SELECT
    'Production.Product',
    COUNT(*),
    SUM(CASE WHEN Color       IS NULL THEN 1 ELSE 0 END),
    'Color',
    SUM(CASE WHEN Size        IS NULL THEN 1 ELSE 0 END),
    'Size',
    SUM(CASE WHEN Weight      IS NULL THEN 1 ELSE 0 END),
    'Weight',
    COUNT(DISTINCT ProductID)
FROM Production.Product

UNION ALL

-- HumanResources.Employee
SELECT
    'HumanResources.Employee',
    COUNT(*),
    0, 'N/A',
    0, 'N/A',
    0, 'N/A',
    COUNT(DISTINCT BusinessEntityID)
FROM HumanResources.Employee

UNION ALL

-- Purchasing.PurchaseOrderHeader
SELECT
    'Purchasing.PurchaseOrderHeader',
    COUNT(*),
    SUM(CASE WHEN ShipDate IS NULL THEN 1 ELSE 0 END),
    'ShipDate',
    0, 'N/A',
    0, 'N/A',
    COUNT(DISTINCT PurchaseOrderID)
FROM Purchasing.PurchaseOrderHeader;
GO


/* ============================================================
   SECTION 3 – VERIFY VIEWS
   Run these after Section 2 to confirm all views are created
   and returning data correctly.
   ============================================================ */

-- List all EDA views created
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'eda'
ORDER BY TABLE_NAME;
GO

-- Quick row count check on each view
SELECT 'vw_SalesOverview'       AS view_name, COUNT(*) AS rows FROM eda.vw_SalesOverview       UNION ALL
SELECT 'vw_SalesLineItems',                   COUNT(*) FROM eda.vw_SalesLineItems               UNION ALL
SELECT 'vw_CustomerProfile',                  COUNT(*) FROM eda.vw_CustomerProfile              UNION ALL
SELECT 'vw_ProductCatalog',                   COUNT(*) FROM eda.vw_ProductCatalog               UNION ALL
SELECT 'vw_EmployeeProfile',                  COUNT(*) FROM eda.vw_EmployeeProfile              UNION ALL
SELECT 'vw_PurchasingOverview',               COUNT(*) FROM eda.vw_PurchasingOverview           UNION ALL
SELECT 'vw_DataHealthSummary',                COUNT(*) FROM eda.vw_DataHealthSummary;
GO

-- Sample preview of each view
SELECT TOP 5 * FROM eda.vw_SalesOverview;
SELECT TOP 5 * FROM eda.vw_SalesLineItems;
SELECT TOP 5 * FROM eda.vw_CustomerProfile;
SELECT TOP 5 * FROM eda.vw_ProductCatalog;
SELECT TOP 5 * FROM eda.vw_EmployeeProfile;
SELECT TOP 5 * FROM eda.vw_PurchasingOverview;
SELECT TOP 10 * FROM eda.vw_DataHealthSummary;
GO


/* ============================================================
   SECTION 4 – POWER BI CONNECTION GUIDE
   ============================================================

   1. Open Power BI Desktop
   2. Home → Get Data → SQL Server
   3. Server   : <your-server-name>\<instance>   (e.g. localhost\SQLEXPRESS)
   4. Database : AdventureWorks2022
   5. Data Connectivity mode: Import  (recommended for EDA)
      – or –  DirectQuery  (live data, slower visuals)
   6. In the Navigator, expand:  AdventureWorks2022 → Views → eda
   7. Select all 7 views → Load

   RECOMMENDED POWER BI VISUALS PER VIEW
   ──────────────────────────────────────
   vw_SalesOverview
       • KPI cards  : total_orders, total_revenue, avg_order_value
       • Line chart : order_month_key (X) vs SUM(TotalDue) (Y)
       • Bar chart  : order_channel vs order_count
       • Map        : territory_name vs SUM(TotalDue)

   vw_SalesLineItems
       • Table      : category → subcategory → product drill-down
       • Scatter    : UnitPrice vs margin_pct (bubble = LineTotal)
       • Bar chart  : top 10 products by gross_profit
       • Histogram  : discount_pct distribution (bin column)

   vw_CustomerProfile
       • KPI cards  : total customers, avg lifetime_value
       • Donut      : customer_type split
       • Map        : CountryRegionCode vs COUNT(CustomerID)
       • Histogram  : avg_order_value distribution

   vw_ProductCatalog
       • Table      : product_status filter + margin_pct sort
       • Scatter    : StandardCost vs ListPrice coloured by category
       • Bar        : category → subcategory → avg margin_pct
       • KPI        : total active products, avg qty_on_hand

   vw_EmployeeProfile
       • KPI cards  : total employees, avg tenure_years
       • Donut      : Gender split, pay_type split
       • Bar        : department_name vs headcount
       • Histogram  : tenure_years distribution

   vw_PurchasingOverview
       • KPI cards  : total POs, total spend, avg lead_time_days
       • Bar        : vendor_name vs TotalDue (top 10)
       • Line       : order_month vs TotalDue trend
       • Box plot   : lead_time_days (use Python visual or bins)

   vw_DataHealthSummary
       • Matrix/Table : all 7 rows showing null counts per table
       • Conditional formatting on null_count columns (red = high)

   ============================================================ */
