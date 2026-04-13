-- sales Order details about discounts

select 
SUM(case when UnitPriceDiscount = 0 then 1 else 0 end) no_discount,
SUM(case when UnitPriceDiscount > 0 then 1 else 0 end) some_discount,
AVG(case when UnitPriceDiscount > 0 then UnitPriceDiscount else NUll end ) * 100 as average_discount,
Max(UnitPriceDiscount) * 100 as max_discount,
MIN(case when UnitPriceDiscount > 0 then UnitPriceDiscount else NULL end) * 100 as min_discount

from Sales.SalesOrderDetail;

-- Result: discount are extremely rare 

select 
MIN(OrderQty) as minimum_order_quantity,
MAX(OrderQty) as maximum_order_quantity,
AVG(OrderQty) as average_order_quantity,
(select top 1 OrderQty from Sales.SalesOrderDetail group by OrderQty order by count(OrderQty) desc) as MODE,
(select top 1 
		PERCENTILE_CONT(0.5) within group (Order by OrderQty desc) over() from Sales.SalesOrderDetail) as median
from Sales.SalesOrderDetail;

select 
Min(ListPrice) as minimum_price,
Max(ListPrice) as maximum_price,
AVG(ListPrice) as average_price,
(select top 1 
		PERCENTILE_CONT(0.5) within group (Order by ListPrice desc) over() from Production.Product
		where SellEndDate is null and ListPrice != 0) as median,
count(*) as Totalproducts
from Production.Product
where SellEndDate is null and ListPrice != 0;

-- average twice of median some product with high price pulling average up
-- also active product are 206 of 504

with cte as
-- creating bucket tiers
	(
		select
		ListPrice,
		CASE
			WHEN ListPrice < 100 then 'Budget under 100'
			WHEN ListPrice >= 100 and ListPrice < 500 then 'Mid_range 100 to 500'
			WHEN ListPrice >= 500 and ListPrice < 1500 then 'Premium 500 to 1500'
			WHEN ListPrice >= 1500 then 'Luxary above 1500'
			END as Tiers
		from Production.Product
		where SellEndDate is null and ListPrice != 0
	)
	select 
	Tiers,
	count(*) as product_count,
	AVG(ListPrice) as average_price,
	COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS pct_of_total
	from cte
	group by Tiers
	order by average_price

