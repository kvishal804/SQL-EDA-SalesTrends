/*
	Date Range for time series 
*/

SELECT
    MIN(OrderDate)                    AS earliest_order,
    MAX(OrderDate)                    AS latest_order,
    COUNT(DISTINCT YEAR(OrderDate))   AS distinct_years
FROM Sales.SalesOrderHeader;


--  total revenue, average order value and highest single order value — grouped by year.

select 
YEAR(OrderDate) as Year,
SUM(TotalDue) as total_revenue,
AVG(TotalDue) as avg_order_value,
MAX(TotalDue) as highest_order
from Sales.SalesOrderHeader
Group by YEAR(OrderDate)

/*
The average order value crashes from 9,623 in 2012 to 3,452 in 2013 — nearly a 65% drop.
This is suspicious. Revenue went UP but average order value went DOWN massively. That can only mean 
one thing — a huge spike in number of orders with smaller values.
*/

/*
calculate order count and average order value grouped by year AND OnlineOrderFlag — 
so we can see if the online order explosion is responsible for that avg drop.
*/

select 
YEAR(OrderDate) as Year,
SUM(Case when OnlineOrderFlag= 1 then 1  end) as Online_orders,
SUM(Case when OnlineOrderFlag= 0 then 1  end) as Offline_orders,
round(AVG(TotalDue),2) as avg_order_value
from Sales.SalesOrderHeader
group by YEAR(OrderDate),OnlineOrderFlag
Order by Year

/*
    Online order grew nearly 4.5 from 2012 to 2013,
    avgerage of offline order each year is higher than online sales
    Online orders are low value, high value - dragging the overall average down
    Businees grow in year 2013 as large number of new order received.
*/
