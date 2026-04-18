CREATE OR ALTER VIEW eda.vw_MonthlyTrend AS
 with month_base as(
select 
Year(OrderDate) as order_year,
Month(OrderDate) as order_month,
DATENAME(MONTH,OrderDate) as month_name,
DATEFROMPARTS(Year(OrderDate),MONTH(OrderDate),1) as date,
CASE 
	WHEN DATEPART(QUARTER,OrderDate) = 1 then 'Q1'
	WHEN DATEPART(QUARTER,OrderDate) = 2 then 'Q2'
	WHEN DATEPART(QUARTER,OrderDate) = 3 then 'Q3'
	else 'Q4'
	end as quarter,
CASE 
	when year(OrderDate) in (2012,2013) then 'Complete'
	else 'Partial'
	end as year_flag,
count(*) as total_orders,
sum(TotalDue) as total_revenue
from Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate),DATEPART(QUARTER,OrderDate), DATENAME(MONTH,OrderDate)
)

select *,
lag(total_revenue) over (order by date) as last_month_sum,
round((total_revenue -lag(total_revenue) over (order by date))*100 
		/lag(total_revenue) over (order by date),2) as growth_pct,
avg(total_revenue) over(order by date rows between 2 preceding and current row) as rolling_3monthavg
from month_base