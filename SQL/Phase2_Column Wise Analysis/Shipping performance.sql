-- shipping performance


select 
MIN(DATEDIFF(DAY,OrderDate,ShipDate)) as Minimum_daystoship,
	Max(DATEDIFF(DAY,OrderDate,ShipDate)) as Maximum_daystoship,
	AVG(DATEDIFF(DAY,OrderDate,ShipDate)) as average_daystoship,
	 (select top 1 PERCENTILE_CONT(0.5) within group (Order by DATEDIFF(DAY,OrderDate,ShipDate)) over() from  Sales.SalesOrderHeader) as median
from Sales.SalesOrderHeader


-- neither rush delivery nor late shipments 
-- stndardised delivery


