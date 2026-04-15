/*
	Do online and offline customers buy different product categories?
*/

select 
case 
	when ordhed.OnlineOrderFlag = 0 then 'Offline'
	else 'Online'
	end 	as Channel,
procat.name as Category,
count(*) as Order_count,
cast (
sum(orddet.LineTotal) as numeric ) as Total_Revenue
/*
	TotalDue lives in SalesOrderHeader — one value per order
LineTotal lives in SalesOrderDetail — one value per line item
Always SUM the column from the many side of the join, never from the one side
*/
from Sales.SalesOrderHeader ordhed
 join Sales.SalesOrderDetail orddet
on ordhed.SalesOrderID = orddet.SalesOrderID 
 join Production.Product pro
on orddet.ProductID = pro.ProductID
 join Production.ProductSubcategory prosub
on pro.ProductSubcategoryID = prosub.ProductSubcategoryID
 join Production.ProductCategory procat
on prosub.ProductCategoryID = procat.ProductCategoryID
group by procat.name,ordhed.OnlineOrderFlag
order by Channel

/*
	no components sold online
	bikes generate most revenue
	online most sold items accessories
*/