/*
Does seasonality exist — do certain months consistently perform better across all years?
*/

select 
year(OrderDate) as YearofOrder,
DATENAME(MONTH,OrderDate) as OrderMonth,
AVG(TotalDue) as average_revenue,
count(*) as total_orders
from Sales.SalesOrderHeader
where Year(OrderDate) in (2012,2013)
group by Year(OrderDate),
Month(OrderDate), DATENAME(MONTH,OrderDate)
Order by YearofOrder,
Month(OrderDate)

/*
		sudden change in order form july 2023 due to online orders
		but average revenue falls sharply 
*/