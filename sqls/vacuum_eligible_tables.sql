-- PURPOSE: Use this sql script to retrieve details from database(s) to generate the list of tables which are eligible for vacumm AND restore occupied DB space

WITH vbt AS (
    SELECT setting AS autovacuum_vacuum_threshold 
    FROM  pg_settings WHERE name = 'autovacuum_vacuum_threshold'
),
vsf AS (
    SELECT setting AS autovacuum_vacuum_scale_factor 
    FROM pg_settings WHERE name = 'autovacuum_vacuum_scale_factor'
), 
fma AS (
    SELECT setting AS autovacuum_freeze_max_age 
    FROM pg_settings WHERE name = 'autovacuum_freeze_max_age'
),
sto AS (
    SELECT opt_oid, split_part(setting, '=', 1) as param, split_part(setting, '=', 2) as value 
    FROM (SELECT oid opt_oid, unnest(reloptions) setting FROM pg_class) opt
)
SELECT '"'||ns.nspname||'"."'||c.relname||'"' as relation,
pg_size_pretty(pg_table_size(c.oid)) as table_size,
age(relfrozenxid) as xid_age,
coalesce(cfma.value::float, autovacuum_freeze_max_age::float) autovacuum_freeze_max_age,
(coalesce(cvbt.value::float, autovacuum_vacuum_threshold::float) +
coalesce(cvsf.value::float,autovacuum_vacuum_scale_factor::float) * c.reltuples)
AS autovacuum_vacuum_tuples, n_dead_tup as dead_tuples 
FROM pg_class c JOIN pg_namespace ns on ns.oid = c.relnamespace 
JOIN pg_stat_all_tables stat on stat.relid = c.oid JOIN vbt on (1=1) JOIN vsf on (1=1) JOIN fma on (1=1)
LEFT JOIN sto cvbt on cvbt.param = 'autovacuum_vacuum_threshold' AND c.oid = cvbt.opt_oid 
LEFT JOIN sto cvsf on cvsf.param = 'autovacuum_vacuum_scale_factor' AND c.oid = cvsf.opt_oid
LEFT JOIN sto cfma on cfma.param = 'autovacuum_freeze_max_age' AND c.oid = cfma.opt_oid
WHERE c.relkind = 'r' AND nspname <> 'pg_catalog'
AND (age(relfrozenxid) >= coalesce(cfma.value::float, autovacuum_freeze_max_age::float)
OR coalesce(cvbt.value::float, autovacuum_vacuum_threshold::float) + 
coalesce(cvsf.value::float,autovacuum_vacuum_scale_factor::float) * 
c.reltuples <= n_dead_tup)
ORDER BY age(relfrozenxid) DESC LIMIT 50;
