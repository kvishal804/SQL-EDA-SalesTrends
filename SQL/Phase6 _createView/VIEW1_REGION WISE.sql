/*
	VIEW SHOWING ONLINE/OFFLINE ORDERS,ORDER TIERS AND REGION WISE DISTRIBUTION
*/

CREATE OR ALTER VIEW eda.vw_SalesSummary AS
SELECT 
SalesOrderID,
OrderDate,
YEAR(OrderDate) AS ORDER_YEAR,
MONTH(OrderDate) AS ORDER_MONTH,
DATENAME(MONTH,OrderDate) AS MONTH_NAME,
TotalDue,
CASE 
	WHEN OnlineOrderFlag = 0 THEN 'OFFLINE'
	ELSE 'ONLINE' 
	END AS CHANNEL,
CAST(DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS DATE) AS month_key,
CASE
		WHEN TotalDue < 500 then 'Budget under 100'
		WHEN TotalDue >= 500 and TotalDue < 1000 then 'Low'
		WHEN TotalDue >= 1000 and TotalDue < 5000 then 'High'
		WHEN TotalDue >= 5000 and TotalDue < 20000 then 'Very High'
		WHEN TotalDue >= 20000 then 'Premium'
		END as Tiers,
CASE 
	WHEN YEAR(OrderDate) IN (2012,2013) THEN 'Full'
	ELSE 'Partial'
	END AS YEAR_FLAG,
	TERR.Name AS TerriotryName,
	TERR.[Group] AS TerriotryGroup,
	TERR.CountryRegionCode
 
FROM Sales.SalesOrderHeader ORDHDR
JOIN Sales.SalesTerritory TERR
ON ORDHDR.TerritoryID = TERR.TerritoryID

/*
	Know which tables to join
	Know that 2011 and 2014 are partial years
	Know how to calculate Channel label from a 0/1 flag
	Know how to build price tiers manually
*/