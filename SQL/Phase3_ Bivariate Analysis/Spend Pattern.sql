/*
	Who spends more — individual customers or store accounts?
*/
with cus as (
-- assign the customer type
		select 
		CustomerID,
		CASE 
    WHEN PersonID IS NOT NULL AND StoreID IS NULL THEN 'Individual'
    WHEN StoreID  IS NOT NULL AND PersonID IS NULL THEN 'Store'
    WHEN PersonID IS NOT NULL AND StoreID IS NOT NULL THEN 'Store Contact'
END AS Customer_type
		from Sales.Customer
		)

		select 
		Customer_type,
		avg(TotalDue) as  avg_order_value,
	Count(*) as order_count,
	sum(TotalDue) as Total_revenue
		from Sales.SalesOrderHeader ordhdr
		left join cus c
		on ordhdr.CustomerID = c.CustomerID
		Group by Customer_type

/*
	store order create most revenue over individual orders

*/

