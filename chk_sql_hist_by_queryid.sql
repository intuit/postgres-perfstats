-- Run it like
-- 1) Get snap_id list
-- pqbopc04p=> \i list_snap.sql

-- 2) Set begin snap id (bsnap) and end snap id (esnap)
-- pqbopc04p=> \set bsnap 90
-- pqbopc04p=> \set esnap 100
-- pqbopc04p=> \set queryid -5279880674695451877

-- 3) Run this script
-- pqbopc04p=> \i chk_sql_hist_by_queryid.sql

select b.snap_id snap_id_end,
       b.snap_time snap_time_end,
       b.userid,
       b.queryid,
       b.calls - coalesce(a.calls, 0) calls,
       b.total_time - coalesce(a.total_time, 0) total_time,
       (b.total_time - coalesce(a.total_time, 0)) / (b.calls - coalesce(a.calls, 0)) avg_time,
       b.min_time cum_min_time,
       b.max_time cum_max_time,
       b.mean_time cum_mean_time,
       b.shared_blks_hit - coalesce(a.shared_blks_hit, 0) shared_blks_hit, 
       b.blk_read_time - coalesce(a.blk_read_time, 0) blk_read_time,
       b.blk_write_time - coalesce(a.blk_write_time, 0) blk_write_time,
       b.query
  from perfstat.pg_stat_statements_hist a right join perfstat.pg_stat_statements_hist b
    on (a.userid = b.userid and a.dbid = b.dbid and a.queryid = b.queryid and a.query = b.query and b.snap_id = a.snap_id + 1) 
  where b.queryid = :queryid
    and b.calls - coalesce(a.calls, 0) != 0
   and a.snap_id >= :bsnap
   and b.snap_id <= :esnap
  order by b.snap_id, b.queryid, b.userid;
