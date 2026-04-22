-- Product Status

SELECT
    CASE WHEN SellEndDate IS NULL THEN 'Active' ELSE 'Discontinued' END AS product_status,
    COUNT(*)        AS product_count,
    AVG(ListPrice)  AS avg_list_price
FROM Production.Product
GROUP BY CASE WHEN SellEndDate IS NULL THEN 'Active' ELSE 'Discontinued' END;

/*
    discontinue product average 3X higher than active one.
    means 
        i)  premium product too expensive to sell and got pulled
        ii) high end product lines were replaced by newer models
*/

select 
c.Name,
count(*) as total_product,
AVG(p.ListPrice) as avg_list_price
from Production.Product p
left join Production.ProductSubcategory s
on p.ProductSubcategoryID = s.ProductSubCategoryID
left join Production.ProductCategory c
on s.ProductCategoryID = c.ProductCategoryID
Group by c.Name;

/*
    premium itmes: Bikes
    variety in components
    accessories & clothing low value: high volume, low value margin
    total products= 295
*/

select 
count(*) as total_products,
sum(Case when ProductSubcategoryID is null then 1 else 0 end) as subcategorynotassigned,
sum(Case when ProductSubcategoryID is not null then 1 else 0 end) as subcategory_assigned
from Production.Product