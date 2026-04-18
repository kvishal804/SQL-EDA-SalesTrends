---------------------------------------------------------------------------------------------------------------
 /*
 Customer Segmentation (RFM Analysis)
 RFM stands for:

R — Recency → How recently did the customer last order?
F — Frequency → How many times have they ordered?
M — Monetary → How much have they spent in total?
 */

 -- raw RFM values for every customer.

select
CustomerID,
MAX(OrderDate) as last_order,
(select Max(OrderDate) from Sales.SalesOrderHeader)last_orderDate ,
count(*) as total_orders,
sum(TotalDue)  as amount_spent,
DATEDIFF(DAY,MAX(OrderDate),(select Max(OrderDate) from Sales.SalesOrderHeader)) day_sincelastorder
from Sales.SalesOrderHeader
Group by CustomerID
 
		

 

 