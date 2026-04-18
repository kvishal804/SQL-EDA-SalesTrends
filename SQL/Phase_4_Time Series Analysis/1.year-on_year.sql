/*
	Year over Year revenue comparison	
*/
----------------------------------------------------------------------------------------------------------------

select 
YEAR(OrderDate) as year_order,
count(*) as total_orders,
cast (sum(TotalDue) as numeric) as total_revenue,
round( avg(TotalDue),2) as avg_ord_value,
case
	when Year(OrderDate) in (2012,2013) then 'Complete'
	else 'Partial'
	end as year_flag
	from Sales.SalesOrderHeader
Group by Year(OrderDate)
Order by year_order

