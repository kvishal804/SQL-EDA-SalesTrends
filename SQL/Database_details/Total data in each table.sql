/*
	how much data we're actually dealing with
*/
SELECT
    s.name  AS schema_name,
    t.name  AS table_name,
    p.rows  AS row_count
FROM sys.tables     t
JOIN sys.schemas    s 
ON s.schema_id = t.schema_id
JOIN sys.partitions p 
ON p.object_id = t.object_id
           AND p.index_id IN (0,1)
ORDER BY p.rows DESC;

