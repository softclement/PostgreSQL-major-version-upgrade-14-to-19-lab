\echo '--- prepared transactions (must be 0)'
SELECT count(*) FROM pg_prepared_xacts;
\echo '--- replication slots'
SELECT slot_name, slot_type, active FROM pg_replication_slots;
\echo '--- invalid indexes (must be empty)'
SELECT indexrelid::regclass FROM pg_index WHERE NOT indisvalid;
\echo '--- reg* columns that pg_upgrade rejects (must be empty)'
SELECT n.nspname, c.relname, a.attname
FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE a.attnum > 0 AND NOT a.attisdropped AND c.relkind IN ('r','m','i')
  AND n.nspname NOT IN ('pg_catalog','information_schema')
  AND a.atttypid IN ('regproc'::regtype, 'regprocedure'::regtype, 'regoper'::regtype,
                     'regoperator'::regtype, 'regconfig'::regtype, 'regdictionary'::regtype);
\echo '--- extensions'
SELECT extname, extversion FROM pg_extension ORDER BY 1;
