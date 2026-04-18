 ------------------------------------------------------------------------------------------------------------------
 /* score each customer on all three dimensions using NTILE(3) — this splits customers into 3 equal groups automatically.

Recency score — lower days = better = score 3 (NTILE reversed)
Frequency score — higher orders = better = score 3
Monetary score — higher spend = better = score 3
*/
 select top 10 *,
   NTILE(3) OVER (ORDER BY day_sincelastorder ASC)  AS recency_score,
    NTILE(3) OVER (ORDER BY total_orders DESC)        AS frequency_score,
    NTILE(3) OVER (ORDER BY amount_spent DESC)        AS monetary_score
 from 
 (
		 select
		 CustomerID,
		 MAX(OrderDate) as last_order,
		 (select Max(OrderDate) from Sales.SalesOrderHeader)last_orderDate ,
		 count(*) as total_orders,
		 sum(TotalDue)  as amount_spent,
		 DATEDIFF(DAY,MAX(OrderDate),(select Max(OrderDate) from Sales.SalesOrderHeader)) day_sincelastorder
		 from Sales.SalesOrderHeader
		 Group by CustomerID
		
 )t