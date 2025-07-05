#!/usr/bin/env bash

#set -x #echo on

#####################################################################################
## Declaration of SQL Queries in the form of constants whcih are called by the function

#####################################################################################

SQL_FETCH_VACUUM_LASTEXECUTED="SELECT relname, schemaname, last_vacuum, last_autovacuum 
                                FROM pg_stat_user_tables;"

SQL_FETCH_ANALYZE_LASTEXECUTED="SELECT relname, schemaname, last_analyze, last_autoanalyze 
                                FROM pg_stat_user_tables;"

SQL_FETCH_VACUUM_IS_RUNNING="SELECT n.nspname || '.' || c.relname AS table, a.datname AS dbname, a.pid, a.state, a.wait_event, current_timestamp - a.xact_start AS running_since, a.query
                            FROM pg_namespace n, pg_stat_activity a, pg_locks l, pg_class c
                            WHERE a.query LIKE 'autovacuum:%'
                            AND l.pid = a.pid
                            AND l.mode = 'ShareUpdateExclusiveLock'
                            AND (c.oid = l.relation OR c.reltoastrelid = l.relation)
                            AND n.oid = c.relnamespace
                            AND n.nspname <> 'pg_toast'
                            ORDER BY a.xact_start;"

SQL_FETCH_VACUUM_SETTINGS="SELECT name, setting, unit, category, short_desc, vartype, min_val, max_val 
                            FROM pg_settings 
                            WHERE name like '%autovacuum%';"

SQL_FETCH_VACUUM_SETTINGS_TABLES="SELECT relname, reloptions, relkind
                                    FROM pg_class
                                    JOIN pg_namespace on pg_namespace.oid = pg_class.relnamespace
                                    WHERE pg_namespace.nspname = 'public' 
                                    AND nspname NOT LIKE 'pg_toast%'
                                    AND relkind = 'r';"

SQL_FETCH_VACUUM_TOTALRUN="SELECT relname, schemaname, vacuum_count, autovacuum_count 
                           FROM pg_stat_user_tables;"

SQL_FETCH_ANALYZE_TOTALRUN="SELECT relname, schemaname, analyze_count, autoanalyze_count 
                            FROM pg_stat_user_tables;"

# Threshold formula for vacuum "50 + 0.1 * c.reltuples" is based on: autovacuum_vacuum_threshold +  autovacuum_vacuum_scale_factor * pg_class.reltuples
SQL_FETCH_DEAD_TUPLES_EXISTS="SELECT s.relname, s.n_dead_tup, 50 + 0.1 \* c.reltuples as vacuum_threshold, s.n_live_tup, s.n_tup_del, s.n_tup_upd, c.reltuples, s.n_dead_tup > (50 + 0.1 \* c.reltuples) as is_vacuum_req 
                                FROM pg_stat_user_tables s 
                                INNER JOIN pg_class c ON s.relname = c.relname 
                                ORDER BY s.n_dead_tup > (50 + 0.1 \* c.reltuples) DESC;"

SQL_FETCH_DB_OBJECTS_SIZE="SELECT pg_size_pretty(pg_total_relation_size(pg_class.oid)) as total_size, pg_size_pretty(pg_relation_size(pg_class.oid)) as obj_size, 
                            pg_size_pretty(pg_total_relation_size(pg_class.oid) - pg_relation_size(pg_class.oid)) as external_size, pg_class.relname, pg_namespace.nspname,
                            CASE pg_class.relkind WHEN 'r' THEN 'table' WHEN 'i' THEN 'index' WHEN 'S' THEN 'sequence' WHEN 'v' THEN 'view' WHEN 't' THEN 'TOAST' ELSE pg_class.relkind::text END as obj_type
                            FROM pg_class 
                            LEFT OUTER JOIN pg_namespace ON (pg_namespace.oid = pg_class.relnamespace)
                            WHERE pg_namespace.nspname = 'public' 
                            ORDER BY pg_relation_size(pg_class.oid) DESC;"

SQL_FETCH_LARGE_TABLES_NOT_VACUUMED="SELECT t.relname, size, last_vacuum, last_autovacuum, now() as curr_time
                                    FROM (SELECT nspname, relname, pg_size_pretty(pg_relation_size(c.oid)) AS size
                                        FROM pg_class c
                                        LEFT JOIN pg_namespace N ON (N.oid = c.relnamespace)
                                        WHERE nspname = 'public' 
                                        ORDER BY pg_relation_size(c.oid) DESC
                                        LIMIT 20) t
                                        LEFT OUTER JOIN pg_stat_user_tables pg on pg.relname = t.relname
                                    WHERE pg.last_autovacuum < now() - interval '1 month';"

SQL_PERFORM_VACUUM_TABLE="VACUUM VERBOSE PG_TABLENAME;"

SQL_PERFORM_ANALYZE_TABLE="ANALYZE VERBOSE PG_TABLENAME;"

SQL_PERFORM_ANALYZE_FULL="ANALYZE;"

SQL_PERFORM_REINDEX_TABLE="REINDEX TABLE PG_TABLENAME;"

SQL_FETCH_TOP_SLOWEST_QUERIES="SELECT query, total_exec_time \* '1 millisecond'::interval as exec_duration, rows
                                FROM pg_stat_statements
                                ORDER BY exec_duration DESC
                                LIMIT 10;"

SQL_FETCH_TOP_SLOWEST_QUERIES_PREQ="CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"


get_vacuum_lastExecuted(){
    echo "${SQL_FETCH_VACUUM_LASTEXECUTED}"
}

get_analyze_lastExecuted(){
    echo "${SQL_FETCH_ANALYZE_LASTEXECUTED}"
}

get_vacuum_isRunning(){
    echo "${SQL_FETCH_VACUUM_IS_RUNNING}"
}

get_vacuum_settings(){
    echo "${SQL_FETCH_VACUUM_SETTINGS}"
}

get_vacuum_settings_tables(){
    echo "${SQL_FETCH_VACUUM_SETTINGS_TABLES}"
}

get_vacuum_totalRun(){
    echo "${SQL_FETCH_VACUUM_TOTALRUN}"
}

get_analyze_totalRun(){
    echo "${SQL_FETCH_ANALYZE_TOTALRUN}"
}

get_deadTuples_exists(){
    echo "${SQL_FETCH_DEAD_TUPLES_EXISTS}"
}

get_vacuum_eligibleTables(){
    echo "${SQL_FETCH_VACUUM_ELIGIBLE_TABLES}"
}

get_db_objects_size(){
    echo "${SQL_FETCH_DB_OBJECTS_SIZE}"
}

get_large_tables_not_vacuumed(){
    echo "${SQL_FETCH_LARGE_TABLES_NOT_VACUUMED}"
}

perform_manual_vacuum_table(){
    echo "${SQL_PERFORM_VACUUM_TABLE}"
}

perform_manual_analyze_table(){
    echo "${SQL_PERFORM_ANALYZE_TABLE}"
}

perform_manual_vacuum_full(){
    echo "${SQL_PERFORM_ANALYZE_FULL}"
}

perform_manual_reindex_table(){
    echo "${SQL_PERFORM_REINDEX_TABLE}"
}

get_top_slowest_queries(){
    echo "${SQL_FETCH_TOP_SLOWEST_QUERIES}"
}

get_top_slowest_queries_PREREQUISITE(){
    echo "${SQL_FETCH_TOP_SLOWEST_QUERIES}"
}

get_top_slowest_queries_preq(){
    echo "${SQL_FETCH_TOP_SLOWEST_QUERIES_PREQ}"
}

