-------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------


 With rfm as 
 (
		 select
		 CustomerID,
		 MAX(OrderDate) as last_order,
		 (select Max(OrderDate) from Sales.SalesOrderHeader)last_orderDate ,
		 count(*) as total_orders,
		 sum(TotalDue)  as amount_spent,
		 avg(TotalDue) as avg_spending,
		 DATEDIFF(DAY,MAX(OrderDate),(select Max(OrderDate) from Sales.SalesOrderHeader)) day_sincelastorder
		 from Sales.SalesOrderHeader
		 Group by CustomerID
 ),
 rfm_mid as (
 select *,
 NTILE(3) OVER (ORDER BY day_sincelastorder ASC)  AS recency_score,
    NTILE(3) OVER (ORDER BY total_orders DESC)        AS frequency_score,
    NTILE(3) OVER (ORDER BY amount_spent DESC)        AS monetary_score
 from rfm
 ),
 rfm_segment as (
 select 
 CustomerID,
 total_orders,
 amount_spent,
 day_sincelastorder,
 avg_spending,
 case
	when recency_score =1 and frequency_score = 1 and monetary_score = 1 then 'Champions'
	when recency_score = 1 and frequency_score != 1 and monetary_score = 1 then 'Loyal Customers'
	when recency_score = 2 then 'Potential Loyalist' 
	when recency_score = 3 and frequency_score = 1 then 'At Risk'
	when recency_score = 3 and frequency_score = 2 then 'Hibernating' 
	else 'Lost' 
	end as Segment
 from rfm_mid
),
 cus as (	select 
		CustomerID,
		CASE 
    WHEN PersonID IS NOT NULL AND StoreID IS NULL THEN 'Individual'
    WHEN StoreID  IS NOT NULL AND PersonID IS NULL THEN 'Store'
    WHEN PersonID IS NOT NULL AND StoreID IS NOT NULL THEN 'Store Contact'
END AS Customer_type
		from Sales.Customer
		
		)

SELECT
    Segment,
	c.customer_type,
    COUNT(*)                        AS customer_count,
    CAST(SUM(amount_spent) AS NUMERIC)  AS total_revenue,
    CAST(AVG(amount_spent) AS NUMERIC)  AS avg_revenue_per_customer,
    AVG(day_sincelastorder)         AS avg_days_since_order,
	SUM(amount_spent) *100 / SUM(SUM(amount_spent)) over() as perc_of_total
FROM rfm_segment rfm_seg
join cus c 
on rfm_seg.CustomerID = c.CustomerID
GROUP BY Segment ,c.customer_type
ORDER BY total_revenue DESC