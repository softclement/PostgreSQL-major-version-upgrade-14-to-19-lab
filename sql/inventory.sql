WITH ns AS (SELECT oid, nspname FROM pg_namespace WHERE nspname IN ('app','audit','archive'))
SELECT item, val FROM (
  SELECT '10 relkind ' || c.relkind::text AS item, count(*)::text AS val
    FROM pg_class c JOIN ns ON ns.oid = c.relnamespace GROUP BY c.relkind
  UNION ALL SELECT '20 functions',  count(*)::text FROM pg_proc p JOIN ns ON ns.oid = p.pronamespace WHERE p.prokind = 'f'
  UNION ALL SELECT '21 procedures', count(*)::text FROM pg_proc p JOIN ns ON ns.oid = p.pronamespace WHERE p.prokind = 'p'
  UNION ALL SELECT '22 aggregates', count(*)::text FROM pg_proc p JOIN ns ON ns.oid = p.pronamespace WHERE p.prokind = 'a'
  UNION ALL SELECT '30 triggers', count(*)::text FROM pg_trigger t
             JOIN pg_class c ON c.oid = t.tgrelid JOIN ns ON ns.oid = c.relnamespace WHERE NOT t.tgisinternal
  UNION ALL SELECT '31 event triggers', count(*)::text FROM pg_event_trigger
  UNION ALL SELECT '32 rules', count(*)::text FROM pg_rewrite r
             JOIN pg_class c ON c.oid = r.ev_class JOIN ns ON ns.oid = c.relnamespace WHERE r.rulename <> '_RETURN'
  UNION ALL SELECT '33 policies', count(*)::text FROM pg_policy
  UNION ALL SELECT '40 enum/domain/range types', count(*)::text FROM pg_type t
             JOIN ns ON ns.oid = t.typnamespace WHERE t.typtype IN ('e','d','r')
  UNION ALL SELECT '41 collations', count(*)::text FROM pg_collation c JOIN ns ON ns.oid = c.collnamespace
  UNION ALL SELECT '42 operators', count(*)::text FROM pg_operator o JOIN ns ON ns.oid = o.oprnamespace
  UNION ALL SELECT '43 text search cfg+dict', (SELECT count(*) FROM pg_ts_config c JOIN ns ON ns.oid = c.cfgnamespace)::text
             || '+' || (SELECT count(*) FROM pg_ts_dict d JOIN ns ON ns.oid = d.dictnamespace)::text
  UNION ALL SELECT '44 extended statistics', count(*)::text FROM pg_statistic_ext s JOIN ns ON ns.oid = s.stxnamespace
  UNION ALL SELECT '45 user casts', count(*)::text FROM pg_cast c WHERE c.oid >= 16384
             AND NOT EXISTS (SELECT 1 FROM pg_depend d WHERE d.classid = 'pg_cast'::regclass AND d.objid = c.oid AND d.deptype = 'e')
  UNION ALL SELECT '50 publications', count(*)::text FROM pg_publication
  UNION ALL SELECT '51 foreign servers', count(*)::text FROM pg_foreign_server
  UNION ALL SELECT '52 large objects', count(*)::text FROM pg_largeobject_metadata
  UNION ALL SELECT '53 roles (non pg_)', count(*)::text FROM pg_roles WHERE rolname !~ '^pg_'
  UNION ALL SELECT '54 databases', string_agg(datname, ',' ORDER BY datname) FROM pg_database
  UNION ALL SELECT '60 rows customers',   count(*)::text FROM app.customers
  UNION ALL SELECT '61 rows orders',      count(*)::text FROM app.orders
  UNION ALL SELECT '62 rows order_items', count(*)::text FROM app.order_items
  UNION ALL SELECT '63 rows events',      count(*)::text FROM app.events
  UNION ALL SELECT '64 rows sessions',    count(*)::text FROM app.sessions
  UNION ALL SELECT '65 rows documents',   count(*)::text FROM app.documents
  UNION ALL SELECT '70 md5 customers', md5(string_agg(md5(t::text), '' ORDER BY customer_id)) FROM app.customers t
  UNION ALL SELECT '71 md5 orders',    md5(string_agg(md5(t::text), '' ORDER BY order_id))    FROM app.orders t
  UNION ALL SELECT '72 md5 documents', md5(string_agg(md5(d.body || encode(d.blob, 'hex')), '' ORDER BY doc_id)) FROM app.documents d
  UNION ALL SELECT '80 seq order_id last_value', last_value::text FROM app.order_id_seq
  UNION ALL SELECT '81 seq invoice last_value',  last_value::text FROM app.invoice_no_seq
  UNION ALL SELECT '90 extensions (may differ until UPDATE)',
             string_agg(extname || ' ' || extversion, ', ' ORDER BY extname) FROM pg_extension
) x ORDER BY item;
