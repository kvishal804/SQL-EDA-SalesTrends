# AdventureWorks 2022 — Exploratory Data Analysis Sales Trends


A complete end-to-end Exploratory Data Analysis project on the Microsoft AdventureWorks 2022 sample database, performed entirely in SQL Server Management Studio (SSMS) with analytical views built for Power BI consumption.

---

## Project Overview

AdventureWorks 2022 is a fictional bicycle manufacturer with sales, production, purchasing and HR data spanning 2011–2014. This project analyses the business across 6 structured phases — from raw schema exploration to production-ready Power BI views .

**Tools Used**
- SQL Server Management Studio (SSMS)
- Microsoft SQL Server 2022
- Microsoft Power BI Desktop

---

## Project Structure

```
AdventureWorks2022-EDA/
│
├── Phase1_SchemaExploration.sql
├── Phase2_UnivariateAnalysis.sql
├── Phase3_BivariateAnalysis.sql
├── Phase4_TimeSeriesAnalysis.sql
├── Phase5_CustomerSegmentation.sql
├── Phase6_PowerBIViews.sql
│
├── Reports/
│   ├── AW2022_Phase1_Findings.docx
│   ├── AW2022_Phase2_Findings.docx
│   ├── AW2022_Phase3_Findings.docx
│   ├── AW2022_Phase4_Findings.docx
│   └── AW2022_Phase5_Findings.docx
│
└── README.md
```
## SQL Concepts Covered

| Concept | Phase |
|---|---|
| System tables (`sys.schemas`, `sys.tables`, `sys.partitions`) | 1 |
| NULL audits with `CASE` + `SUM` | 1 |
| `PERCENTILE_CONT` with `OVER()` | 2 |
| `NTILE` for equal bucketing | 2, 5 |
| `STDEV` for spread analysis | 2 |
| Fan-out problem in one-to-many joins | 3 |
| `LEFT JOIN` vs `INNER JOIN` for data retention | 3, 6 |
| Multi-table joins across 5 tables | 3 |
| `LAG()` for period-over-period comparison | 4 |
| Rolling averages with `ROWS BETWEEN` | 4 |
| `RANK()` for performance ranking | 4 |
| Multi-layer CTEs | 5, 6 |
| RFM scoring methodology | 5 |
| `CREATE OR ALTER VIEW` | 6 |
| Schema creation and management | 6 |

---

## Phases

### Phase 1 — Schema Exploration
**Goal:** Understand the database structure, identify data quality issues and establish a foundation for analysis.

**Key SQL Concepts:**`sys.schemas`,`sys.tables`,sys.partitions`, `INFORMATION_SCHEMA`, NULL audits, `CASE` statements

---

### Phase 2 — Univariate Analysis
**Goal:** Understand the distribution of individual columns — central tendency, spread, outliers and segmentation.

**Key SQL Concepts:** `PERCENTILE_CONT`, `STDEV`, `NTILE`, `CASE` bucketing, window functions, `SUM(COUNT(*)) OVER()`



---

### Phase 3 — Bivariate Analysis
**Goal:** Explore relationships between two variables to identify business drivers and patterns.

**Key SQL Concepts:** Multi-table JOINs, `LEFT JOIN` vs `INNER JOIN`, fan-out problem, `SUM(LineTotal)` vs `SUM(TotalDue)`, CTEs



---

### Phase 4 — Time Series Analysis
**Goal:** Understand revenue trends over time, identify seasonality and measure growth rates.

**Key SQL Concepts:** `LAG()`, `DATEPART`, `DATENAME`, `DATEFROMPARTS`, rolling averages with `ROWS BETWEEN`, `RANK()`



---

### Phase 5 — Customer Segmentation (RFM Analysis)
**Goal:** Segment customers by Recency, Frequency and Monetary value to identify high-value accounts, at-risk customers and lost customers.

**Key SQL Concepts:** `NTILE(3)`, multi-layer CTEs, `DATEDIFF`, `MAX()` as reference date, RFM scoring logic

**RFM Segments:**

| Segment | Customers | Total Revenue | Avg per Customer |
|---|---|---|---|
| Champions | 1,555 | £63.0M | £40,503 |
| Potential Loyalist | 6,373 | £31.5M | £4,943 |
| At Risk | 1,793 | £21.6M | £12,029 |
| Lost | 8,823 | £5.3M | £603 |
| Loyal Customers | 575 | £1.8M | £3,199 |



---

### Phase 6 — Power BI Views
**Goal:** Build production-ready SQL views in a dedicated `eda` schema encapsulating all business rules discovered across Phases 1–5.

**Key SQL Concepts:** `CREATE OR ALTER VIEW`, schema creation, `LEFT JOIN`, `ISNULL`, `DATEFROMPARTS`, `CAST`, `GO` batch separator

**Views Created:**

| View | Purpose | Key Business Rules Applied |
|---|---|---|
| `eda.vw_SalesSummary` | Revenue, orders, channel, territory | Year flag, channel label, order value buckets, territory join |
| `eda.vw_ProductPerformance` | Products, categories, margins | LEFT JOIN for uncategorised products, margin %, price tiers, status flag |
| `eda.vw_CustomerSegment` | RFM segments, customer types | Full RFM scoring, segment labels, customer type classification |
| `eda.vw_MonthlyTrend` | Time series with growth metrics | LAG for MoM growth, rolling 3-month average, year flag, quarter labels |

---

## Power BI Connection

1. Open **Power BI Desktop**
2. Home → **Get Data** → **SQL Server**
3. Enter your server name (e.g. `localhost\SQLEXPRESS`)
4. Database: `AdventureWorks2022`
5. Data Connectivity mode: **Import** *(recommended for historical EDA)*
6. Navigator → expand **Views** → **eda**
7. Select all 4 views → **Load**

> **Import vs Direct Query:** Use Import mode for this project. The data is historical, views contain complex calculations (rolling averages, RFM scores, LAG functions) and Import mode delivers significantly faster visual interactions.

---

## Prerequisites

- Microsoft SQL Server 2022 (or compatible version)
- SQL Server Management Studio (SSMS)
- AdventureWorks2022 database — [Download from Microsoft](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure)
- Microsoft Power BI Desktop — [Download free](https://powerbi.microsoft.com/desktop)

---

## How to Run

1. Download and restore `AdventureWorks2022.bak` to your SQL Server instance
2. Open SSMS and connect to your server
3. Run scripts in order — Phase1 through Phase6
4. Phase 6 creates the `eda` schema and all 4 views automatically
5. Connect Power BI using Import mode as described above

---


