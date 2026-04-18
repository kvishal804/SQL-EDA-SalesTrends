
CREATE OR ALTER VIEW eda.vw_CustomerSegment AS

with  rfm_base as (
SELECT 
	CustomerID,
	MAX(OrderDate) AS last_orderdate,
	(select MAX(OrderDate) from Sales.SalesOrderHeader) AS max_date,
	DATEDIFF(DAY,MAX(OrderDate),(select MAX(OrderDate) from Sales.SalesOrderHeader)) as day_sincelastorder,
	COUNT(*) AS total_orders,
	SUM(TotalDue) AS total_spending
FROM Sales.SalesOrderHeader
Group by CustomerID
) ,
rfm_score as (
select 
*,
		NTILE(3) over(Order by day_sincelastorder ASC) as recency_score,
		NTILE(3) over(order by total_orders desc) as frequency_score,
		NTILE(3) over(Order by total_spending desc) as monetary_score
from rfm_base
),
rfm_segment as (
select 
	CustomerID,
	total_spending,
	total_orders,
	day_sincelastorder,
	 case
		when recency_score =1 and frequency_score = 1 and monetary_score = 1 then 'Champions'
		when recency_score = 1 and frequency_score != 1 and monetary_score = 1 then 'Loyal Customers'
		when recency_score = 2 then 'Potential Loyalist' 
		when recency_score = 3 and frequency_score = 1 then 'At Risk'
		when recency_score = 3 and frequency_score = 2 then 'Hibernating' 
		else 'Lost' 
	end as Segment
	from rfm_score
	),
	cus_segment as (
	select 
	CustomerID,
	CASE
		WHEN PersonID is not null and StoreID is null then 'Individual'
		WHEN PersonID is null and StoreID is not null then 'Store'
		else 'Store Contact' 
		END as CustomerType
	from Sales.Customer
	)

	select 
	rfm.CustomerID,
	total_spending,
	total_orders,
	day_sincelastorder,
	Segment,
	CustomerType
	from rfm_segment rfm
	join cus_segment cus
	on rfm.CustomerID = cus.CustomerID