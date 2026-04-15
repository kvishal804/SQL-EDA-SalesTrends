/*
Phase 3 — Bivariate Analysis
We're exploring relationships between two variables to find business insights that 
single column analysis can't reveal.
*/

---------------------------------------------------------
-- Do discounts lead to bigger orders? 
---------------------------------------------------------
with discount_flag as 
(
select 
SalesOrderID,
LineTotal,
	case 
		when UnitPriceDiscount = 0 then 1
		else 0
		end as Dis_flag
from Sales.SalesOrderDetail
)
select 
AVG(case when Dis_flag = 0 then LineTotal else null end) as discount_line,
AVG(case when Dis_flag = 0 then TotalDue else null end) as discount_Total,
AVG(case when Dis_flag != 0 then LineTotal else null end) as non_discount_line,
AVG(case when Dis_flag != 0 then TotalDue else null end) as no_discount_Total

from Sales.SalesOrderHeader ord
join discount_flag df
on ord.SalesOrderID = df.SalesOrderID


/*
	discount offered to higher high value product
		higher discount_line price
		Much larger overall orders
*/