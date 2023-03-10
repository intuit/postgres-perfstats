-- Run it like
-- 1) Get snap_id list
-- pqbopc04p=> \i list_snap.sql 

-- 2) Set begin snap id (bsnap) and end snap id (esnap)
-- pqbopc04p=> \set bsnap 90
-- pqbopc04p=> \set esnap 100 
-- pqbopc04p=> \set string 'txdetails_1' 

-- 3) Run this script
-- pqbopc04p=> \i chk_sql_hist.sql

select a.snap_id snap_id_begin,
       b.snap_id snap_id_end,
       a.snap_time snap_time_begin,
       b.snap_time snap_time_end,
       b.userid,
       b.queryid,
       b.calls - coalesce(a.calls, 0) calls,
       b.total_time - coalesce(a.total_time, 0) total_time,
       (b.total_time - coalesce(a.total_time, 0)) / (b.calls - coalesce(a.calls, 0)) avg_time,
       b.min_time cum_min_time,
       b.max_time cum_max_time,
       b.mean_time cum_mean_time,
       b.rows - coalesce(a.rows, 0) "rows",
       b.shared_blks_hit - coalesce(a.shared_blks_hit, 0) shared_blks_hit,
       b.shared_blks_read - coalesce(a.shared_blks_read, 0) shared_blks_read,
       b.shared_blks_written - coalesce(a.shared_blks_written, 0) shared_blks_written,
       b.local_blks_hit - coalesce(a.local_blks_hit, 0) local_blks_hit,
       b.local_blks_read - coalesce(a.local_blks_read, 0) local_blks_read,
       b.local_blks_written - coalesce(a.local_blks_written, 0) local_blks_written,
       b.blk_read_time - coalesce(a.blk_read_time, 0) blk_read_time,
       b.blk_write_time - coalesce(a.blk_write_time, 0) blk_write_time,
       b.query
  from perfstat.pg_stat_statements_hist a right join perfstat.pg_stat_statements_hist b
    on (a.userid = b.userid and a.dbid = b.dbid and a.queryid = b.queryid and a.query = b.query and a.snap_id = :bsnap)
 where b.calls - coalesce(a.calls, 0) != 0
   and b.snap_id = :esnap  
   and b.query like '%' || :'string' || '%'
  order by b.queryid, b.userid;
