-- Comprehensive PostgreSQL database state query for The Zoo
-- Run with: docker exec -e PGPASSWORD=zoopassword postgres psql -U postgres -f /path/to/this/file.sql

-- Show all databases with sizes and owners
\echo '=== DATABASES ==='
SELECT 
    datname AS "Database",
    pg_size_pretty(pg_database_size(datname)) AS "Size",
    pg_catalog.pg_get_userbyid(datdba) AS "Owner",
    datcollate AS "Collation"
FROM pg_database 
WHERE datistemplate = false 
ORDER BY 
    CASE WHEN datname = 'postgres' THEN 0 
         WHEN datname = 'zoodb' THEN 1 
         ELSE 2 END,
    pg_database_size(datname) DESC;

-- Show all users/roles
\echo ''
\echo '=== USERS/ROLES ==='
SELECT 
    rolname AS "User",
    CASE 
        WHEN rolsuper THEN 'SUPERUSER' 
        ELSE 'Regular User' 
    END AS "Type",
    CASE WHEN rolcanlogin THEN 'Yes' ELSE 'No' END AS "Can Login",
    CASE WHEN rolcreatedb THEN 'Yes' ELSE 'No' END AS "Create DB",
    COALESCE(
        (SELECT string_agg(d.datname, ', ' ORDER BY d.datname) 
         FROM pg_database d 
         WHERE d.datdba = r.oid AND d.datistemplate = false),
        ''
    ) AS "Owns Databases"
FROM pg_roles r
WHERE rolname NOT LIKE 'pg_%'
ORDER BY 
    CASE WHEN rolsuper THEN 0 ELSE 1 END,
    rolname;

-- Show connection info for each site
\echo ''
\echo '=== SITE DATABASE CONNECTIONS ==='
SELECT 
    REPLACE(datname, '_db', '') AS "Site",
    datname AS "Database",
    datname || '_user' AS "Username",
    datname || '_pw' AS "Password",
    'postgresql://' || datname || '_user:' || datname || '_pw@postgres.zoo:5432/' || datname AS "Connection String"
FROM pg_database
WHERE datname LIKE '%_db' 
    AND datname NOT IN ('miniflux_db')  -- miniflux has custom setup
ORDER BY datname;

-- Show table counts for each database
\echo ''
\echo '=== TABLE COUNTS BY DATABASE ==='
SELECT 
    n.nspname AS "Database",
    COUNT(c.oid) AS "Tables",
    pg_size_pretty(SUM(pg_total_relation_size(c.oid))::bigint) AS "Total Size"
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r' 
    AND n.nspname NOT IN ('pg_catalog', 'information_schema')
GROUP BY n.nspname
ORDER BY COUNT(c.oid) DESC;

-- For each database, show its tables (example with onlinegrocery_db)
\c onlinegrocery_db
\echo ''
\echo '=== ONLINEGROCERY DATABASE DETAILS ==='
SELECT 
    schemaname AS "Schema",
    tablename AS "Table",
    tableowner AS "Owner",
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS "Size",
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = tablename) AS "Columns"
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- Show record counts
SELECT 
    'orders' AS "Table",
    COUNT(*) AS "Records",
    COALESCE(MAX(order_date)::text, 'No orders yet') AS "Latest Entry"
FROM orders
UNION ALL
SELECT 
    'order_items',
    COUNT(*),
    COALESCE(MAX(id)::text, 'No items yet')
FROM order_items;