select 
count(*) as Total_customer,
SUM(case when PersonID is not null then 1 else 0 end) as have_personID,
SUM(case when PersonID is  null then 1 else 0 end) as no_personID,
SUM(case when StoreID is not null then 1 else 0 end) as have_storeId,
SUM(case when PersonID is not null then 1 else 0 end) + 
SUM(case when StoreID is not null then 1 else 0 end)  as customer_check
from Sales.Customer;

/*
As sum of person with personID & StoreID is greater than total customers.
some customer are assigned both personID & storeID
*/

select Top 10
c.CustomerID,
count(*) as totalorders,
SUM(s.TotalDue) as totalspend
from Sales.Customer c
join Sales.SalesOrderHeader s
on c.CustomerID = s.CustomerID
Group by c.CustomerID
Order by totalspend desc

/*
The 12 orders pattern is interesting — that's exactly 1 order per month across a
full year. These are almost certainly store accounts on regular purchasing contracts,
not random individual buyers.

*/