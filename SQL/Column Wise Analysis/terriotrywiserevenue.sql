/*
	Revenue by territory
*/

select 
t.Name,
count(*) as order_count,
cast(Sum(TotalDue) as numeric) as total_revenue,
cast(AVG(TotalDue) as numeric) as avg_ordervalue,
cast(Sum(TotalDue) * 100 / SUM(Sum(TotalDue)) over() as numeric) as perc_oftotalrevenue
from Sales.SalesOrderHeader o
join Sales.SalesTerritory t
on o.TerritoryID = t.TerritoryID
group by o.TerritoryID,t.Name
order by total_revenue desc;

/*
	Most revenue from southwest america
	highest order from australia but low average value
	southeast & central least order but high average
*/