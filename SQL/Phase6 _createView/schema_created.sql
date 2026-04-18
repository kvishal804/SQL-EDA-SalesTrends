IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'eda')
    EXEC('CREATE SCHEMA eda');
GO

SELECT name FROM sys.schemas WHERE name = 'eda';



/*
    to check view created */
    SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'eda'
ORDER BY TABLE_NAME
