-- Monthly revenue trends

select 
YEAR(OrderDate) as Year,
Datename(MONTH,OrderDate) as Month,
count(*) as order_count,
cast(Sum(TotalDue) as numeric)as total_revenue
from Sales.SalesOrderHeader
group by Year(OrderDate),Month(OrderDate),Datename(MONTH,OrderDate)
Order by Year , Month(OrderDate)
