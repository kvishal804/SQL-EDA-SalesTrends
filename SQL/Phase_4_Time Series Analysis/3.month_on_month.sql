----------------------------------------------------------------------------------------------------------------
-- Month over month revenue growth rate.
----------------------------------------------------------------------------------------------------------------

select *,
round((Total_revenue - previous_month)* 100/previous_month,2) as pec_monthly_growth
from (
		select 
		YEAR(OrderDate) as Yearly,
		DATENAME(MONTH,OrderDate) as Months,
		round(SUM(TotalDue),2) as Total_revenue,
		Lag(SUM(TotalDue)) over(Order by Year(OrderDate) , month(OrderDate) asc) as previous_month
		from Sales.SalesOrderHeader
		group by YEAR(OrderDate), month(OrderDate), DATENAME(MONTH,OrderDate)
)t

