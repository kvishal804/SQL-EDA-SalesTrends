/* 
	Does order value vary by territory AND channel combined?
*/

select 

case 
	when OnlineOrderFlag = 0 then 'Offline'
	else 'Online'
	end as Channel,
saleterr.Name as TerritotyName,
cast(avg(TotalDue) as numeric) as avg_sales

from Sales.SalesOrderHeader salhed
join Sales.SalesTerritory saleterr
on salhed.TerritoryID = saleterr.TerritoryID
group by salhed.TerritoryID,OnlineOrderFlag,Name
order by Channel;

/*
	central territory is mostly offline sales
	most online sales in australia but 10 times smaller than offline

*/


select 
saleterr.Name as TerritotyName,
cast (
avg(case when OnlineOrderFlag = 0 then TotalDue else null end) as numeric ) as offlineorders,
cast ( avg(case when OnlineOrderFlag != 0 then TotalDue else null end) as numeric ) as onlineorders

from Sales.SalesOrderHeader salhed
join Sales.SalesTerritory saleterr
on salhed.TerritoryID = saleterr.TerritoryID
group by salhed.TerritoryID,Name
order by TerritotyName;