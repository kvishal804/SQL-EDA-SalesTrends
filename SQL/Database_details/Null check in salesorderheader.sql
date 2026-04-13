/*
to count how many NULL values exist in these 5 columns of Sales.SalesOrderHeader:
SalesPersonID
CurrencyRateID
ShipDate
PurchaseOrderNumber
Comment
We also want to know the total row count of the table.
*/

select 
	COUNT(*) as total_rows,
	SUM(CASE WHEN SalesPersonID is null THEN 1 ELSE 0 END) as null_salesperson,
	SUM(CASE WHEN CurrencyRateID is null THEN 1 ELSE 0 END) as null_currencyrate,
	SUM(CASE WHEN ShipDate is null THEN 1 ELSE 0 END) as null_shipdate,
	SUM(CASE WHEN PurchaseOrderNumber is null THEN 1 ELSE 0 END) as null_purchaseordernumber,
	SUM(CASE WHEN Comment is null THEN 1 ELSE 0 END) as null_comment
from Sales.SalesOrderHeader;

/*
	null_salesperson mean order booked online
*/

/*
Null check in OnlineOrderFlag
*/

select 
OnlineOrderFlag,
count(*) as OrderType
from Sales.SalesOrderHeader
group by OnlineOrderFlag;

-- here null is intentional it shows these order placed online.