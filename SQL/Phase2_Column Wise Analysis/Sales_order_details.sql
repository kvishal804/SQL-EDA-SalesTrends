/*
Phase 2 — Univariate Analysis is about looking at one column at a time and understanding its distribution.
*/

with stats as
		(
			select 
			TotalDue,
			PERCENTILE_CONT(0.5) WITHIN GROUP (Order by TotalDue) over() as median
			from Sales.SalesOrderHeader
		)
select 
MAX(TotalDue) as Maximum_value,
MIN(TotalDue) as Minimum_value,
AVG(TotalDue) as Average,
MAX(median) as median,
STDEV(TotalDue) as Standard_deviation
from stats ;

/*
	median 865 large number of small orders
	average 3 times median
	standard deviation is 3 times average
*/

With average_cal as
	(
		select 
		TotalDue,
		AVG(TotalDue) over() as average
		from Sales.SalesOrderHeader
	)

select 
SUM (CASE When TotalDue <= average then 1 else 0 END) as Orderbelow_avg,
SUM (CASE When TotalDue > average then 1 else 0 END) as Orderabove_avg,
SUM(CASE WHEN TotalDue <= average THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS pct_below,
SUM(CASE WHEN TotalDue > average THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS pct_above

from average_cal;

-- 87 % order below average skew result prefer median

with cte as(
select 
TotalDue,
Case 
	when TotalDue <=500 then '0-500 bucket'
	when TotalDue > 500 and TotalDue <=1000 then '501-1000 bucket'
	when TotalDue > 1000 and TotalDue <=5000 then '1001-5000 bucket'
	when TotalDue > 5000 and TotalDue <=20000 then '5000-20000  bucket'
	when TotalDue > 20000 then '20001 and above bucket'
END as Buckets
from Sales.SalesOrderHeader
)

select 
Buckets,
count(*) as Total_counts,
COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS pct_of_total
from cte
Group by Buckets
Order by MIN(TotalDue);

/*
	Most sold product are below 500 or in range 1001-5000
*/



