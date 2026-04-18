-----------------------------------------------------------------------------------------------------------------
/* Rolling 3 month average — smoothing the trend. */
-----------------------------------------------------------------------------------------------------------------

select 
Yearly,
months,
montlyrevenue,
-- rolling total query
AVG(montlyrevenue) 
over(Order by yearly, mon
rows between 2 preceding  and current row ) as three_month_avg
from(
-- finding monthly revenue using this sybquery
		select 
		Year(OrderDate) as Yearly ,
		month(OrderDate) as mon ,
		Datename(MONTH,OrderDate) as months,
		round(SUM(TotalDue),2) as montlyrevenue
		from Sales.SalesOrderHeader
		group by year(OrderDate),month(OrderDate), Datename(MONTH,OrderDate)
		)t
