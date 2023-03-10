-- Run it like
-- 1) Get snap_id list
-- pqbopc04p=> \i list_snap.sql 

-- 2) Set begin snap id (bsnap) and end snap id (esnap)
-- pqbopc04p=> \set bsnap 90
-- pqbopc04p=> \set esnap 100
-- pqbopc04p=> \set schema qbo_data
-- pqbopc04p=> \set table txdetails_1

-- 3) Run this script
-- pqbopc04p=> \i chk_index_hist.sql

select a.snap_id snap_id_begin,
       b.snap_id snap_id_end,
       a.snap_time snap_time_begin,
       b.snap_time snap_time_end,
       b.schemaname,
       b.relname,
       b.indexrelname,
       b.idx_scan - coalesce(a.idx_scan, 0) idx_scan,
       b.idx_tup_read - coalesce(a.idx_tup_read, 0) idx_tup_read,
       b.idx_tup_fetch - coalesce(a.idx_tup_fetch, 0) idx_tup_fetch
  from perfstat.pg_stat_all_indexes_hist a right join perfstat.pg_stat_all_indexes_hist b
    on (a.schemaname = b.schemaname and a.relname = b.relname and a.indexrelname = b.indexrelname and a.snap_id = :bsnap)
 where b.schemaname = :'schema'
   and b.relname = :'table'
   and b.snap_id = :esnap
   order by b.snap_id, b.schemaname, b.relname, b.indexrelname; 
