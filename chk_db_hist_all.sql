-- Run it like
-- pqbopc04p=> \i chk_db_hist_all.sql

select b.snap_id snap_id_end,
       b.snap_time snap_time_end,
       b.numbackends cum_numbackends,
       b.xact_commit - coalesce(a.xact_commit, 0) xact_commit,
       b.xact_rollback - coalesce(a.xact_rollback, 0) xact_rollback,
       b.blks_read- coalesce(a.blks_read, 0) blks_read,
       b.blks_hit - coalesce(a.blks_hit, 0) blks_hit,
       b.tup_returned - coalesce(a.tup_returned, 0) tup_returned,
       b.tup_fetched - coalesce(a.tup_fetched, 0) tup_fetched,
       b.tup_inserted - coalesce(a.tup_inserted, 0) tup_inserted,
       b.tup_updated - coalesce(a.tup_updated, 0) tup_updated,
       b.tup_deleted - coalesce(a.tup_deleted, 0) tup_deleted,
       b.temp_files - coalesce(a.temp_files, 0) temp_files,
       b.temp_bytes- coalesce(a.temp_bytes, 0) temp_bytes,
       b.deadlocks - coalesce(a.deadlocks, 0) deadlocks,
       b.blk_read_time - coalesce(a.blk_read_time, 0) blk_read_time,
       b.blk_write_time - coalesce(a.blk_write_time, 0) blk_write_time
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.datid = b.datid and b.snap_id = a.snap_id + 1)
 order by b.snap_id;
