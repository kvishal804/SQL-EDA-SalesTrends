
CREATE OR ALTER VIEW eda.vw_ProductPerformance AS

SELECT 
		ProductID,
		PRO.Name AS Product_Name,
		ProductNumber,
		Color,
		Size,
		ListPrice,
		StandardCost,
		ListPrice - StandardCost AS Unit_Margin,
		ROUND((ListPrice - StandardCost) * 100/ListPrice,2) AS Margin_percent,
		CASE
			WHEN ListPrice <100 THEN 'Budget'
			WHEN ListPrice >=100 AND ListPrice < 500 THEN 'Mid-Range'
			WHEN ListPrice >= 500 AND ListPrice < 1500 THEN 'Premium'
			ELSE 'Luxary'
		END AS Price_tier,
		CASE
		WHEN SellEndDate IS NOT NULL THEN 'Active'
		ELSE 'Discontinued'
		END Product_status,
		ISNULL(PROSUB.Name,'Nocategory') AS Subcategory_name,
		ISNULL(PROCAT.Name,'NoCategory') AS Category_name
FROM Production.Product PRO
LEFT JOIN Production.ProductSubcategory PROSUB
ON PRO.ProductSubcategoryID =PROSUB.ProductSubcategoryID
LEFT JOIN Production.ProductCategory PROCAT
ON PROSUB.ProductCategoryID = PROCAT.ProductCategoryID
--for active products with ListPrice > 0 
  WHERE ListPrice > 0 
