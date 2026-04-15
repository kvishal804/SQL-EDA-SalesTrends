/*
	Which product categories drive the most revenue per order for Store Contact vs Individual customers?
*/

WITH cus_type AS (
    SELECT
        CustomerID,
        CASE
            WHEN PersonID IS NOT NULL AND StoreID IS NULL THEN 'Individual'
            WHEN PersonID IS NOT NULL AND StoreID IS NOT NULL THEN 'Store Contact'
        END AS customer_type
    FROM Sales.Customer
	)
select 
 ct.customer_type,
	procat.Name as Category_name,
	cast (sum(orddtl.LineTotal) as numeric)	as TotalRevenue,
	count(*) as total_order_value
from cus_type ct
join Sales.SalesOrderHeader ordhdr
on ct.CustomerID = ordhdr.CustomerID
join Sales.SalesOrderDetail orddtl
on ordhdr.SalesOrderID = orddtl.SalesOrderID
join Production.Product pro
on orddtl.ProductID = pro.ProductID
join Production.ProductSubcategory prosub
on pro.ProductSubcategoryID = prosub.ProductSubcategoryID
join Production.ProductCategory procat
on prosub.ProductCategoryID = procat.ProductCategoryID
group by procat.Name,
		 ct.customer_type
Order by ct.customer_type, TotalRevenue desc

/*
    Bikes dominates both customer_type
    components are sold exclusively by store no online
*/