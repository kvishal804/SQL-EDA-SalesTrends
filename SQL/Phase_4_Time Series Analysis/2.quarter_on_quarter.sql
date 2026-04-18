----------------------------------------------------------------------------------------------------------------
--Quarter by quarter breakdown.
----------------------------------------------------------------------------------------------------------------

select 
YEAR(OrderDate) as year_order,
case
	when DatePart(QUARTER,OrderDate) = 1 then 'Q1'
	when DatePart(QUARTER,OrderDate) = 2 then 'Q2'
	when DatePart(QUARTER,OrderDate) = 3 then 'Q3'
	else 'Q4'
	end as quarter_wise,
count(*) as total_orders,
cast (sum(TotalDue) as numeric) as total_revenue,
round( avg(TotalDue),2) as avg_ord_value

	from Sales.SalesOrderHeader
Group by Year(OrderDate),DatePart(QUARTER,OrderDate)
Order by year_order,quarter_wise

