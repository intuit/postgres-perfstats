-- Run it like
-- 1) Get snap_id list
-- pqbopc04p=> \i list_snap.sql 

-- 2) Set begin snap id (bsnap) and end snap id (esnap)
-- pqbopc04p=> \set bsnap 90
-- pqbopc04p=> \set esnap 100
-- pqbopc04p=> \set schema qbo_data
-- pqbopc04p=> \set table txdetails_1

-- 3) Run this script
-- pqbopc04p=> \i chk_table_hist.sql

select a.snap_id snap_id_begin,
       b.snap_id snap_id_end,
       a.snap_time snap_time_begin,
       b.snap_time snap_time_end,
       b.schemaname,
       b.relname,
       b.seq_scan - coalesce(a.seq_scan, 0) seq_scan,
       b.seq_tup_read - coalesce(a.seq_tup_read, 0) seq_tup_read,
       b.idx_scan - coalesce(a.idx_scan, 0) idx_scan,
       b. idx_tup_fetch - coalesce(a.idx_tup_fetch, 0) idx_tup_fetch,
       b.n_tup_ins - coalesce(a.n_tup_ins, 0) n_tup_ins,
       b.n_tup_upd - coalesce(a.n_tup_upd, 0) n_tup_upd,
       b.n_tup_del - coalesce(a.n_tup_del, 0) n_tup_del,
       b.n_tup_hot_upd - coalesce(a.n_tup_hot_upd, 0) n_tup_hot_upd,
       b.n_live_tup - coalesce(a.n_live_tup, 0) n_live_tup,
       b.n_dead_tup - coalesce(a.n_dead_tup, 0) n_dead_tup,
       b.n_mod_since_analyze - coalesce(a.n_mod_since_analyze, 0) n_mod_since_analyze,
       b.last_vacuum,
       b.last_autovacuum,
       b.last_analyze,
       b.last_autoanalyze,
       b.vacuum_count - coalesce(a.vacuum_count, 0) vacuum_count,
       b.autovacuum_count - coalesce(a.autovacuum_count, 0) autovacuum_count,
       b.analyze_count - coalesce(a.analyze_count, 0) analyze_count,
       b.autoanalyze_count - coalesce(a.autoanalyze_count, 0) autoanalyze_count
  from perfstat.pg_stat_all_tables_hist a right join perfstat.pg_stat_all_tables_hist b
    on (a.schemaname = b.schemaname and a.relname = b.relname and a.snap_id = :bsnap)
  where b.schemaname = :'schema'
    and b.relname = :'table'
    and b.snap_id = :esnap
    order by b.snap_id, b.schemaname, b.relname; 
