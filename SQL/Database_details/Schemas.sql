/*
    how many schemas exist in AdventureWorks and how many tables are in each one
*/

SELECT
    s.name        AS schema_name,
    COUNT(t.name) AS table_count
FROM sys.schemas s
JOIN sys.tables  t ON t.schema_id = s.schema_id
GROUP BY s.name
ORDER BY table_count DESC;