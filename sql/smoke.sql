\echo '--- procedure + partition routing'
CALL app.place_order(1, 1, 2);
SELECT order_id, order_date, total FROM app.orders ORDER BY order_id DESC LIMIT 1;
\echo '--- partition pruning (expect only orders_2026 is scanned)'
EXPLAIN (COSTS OFF) SELECT * FROM app.orders WHERE order_date = '2026-03-01';
\echo '--- foreign table'
SELECT * FROM app.ft_daily_kpi ORDER BY kpi_date DESC LIMIT 3;
\echo '--- materialized view'
REFRESH MATERIALIZED VIEW CONCURRENTLY app.mv_sales_by_month;
\echo '--- large object'
SELECT convert_from(lo_get(900001), 'UTF8');
\echo '--- RLS as app_ro'
SET ROLE app_ro; SELECT count(*) FROM app.customers; RESET ROLE;
\echo '--- event trigger logged DDL?'
SELECT count(*) > 0 AS ddl_logged FROM audit.ddl_log;
\echo '--- rule protects row'
DELETE FROM app.cache_entries WHERE k = 'protected';
SELECT count(*) AS protected_row_still_there FROM app.cache_entries WHERE k = 'protected';
