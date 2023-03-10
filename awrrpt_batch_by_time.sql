-- Purpose: To generate Aurora Postgres AWR report for all instances as batch by giving begin and end times
-- Usage:  
--     psql --username=<username> -h <cluster endpoint> -p <port> <db name> -f awrrpt_batch_by_time.sql -v begin_time='yyyy-mm-dd hh24:mi:ss' -v end_time='yyyy-mm-dd hh24:mi:ss'
-- Example:
--     psql --username=postgres -h pqbo-prf-c12.cluster-cozwkqglitfx.us-west-2.rds.amazonaws.com -p 5432 pqboc12p -f awrrpt_batch_by_time.sql -v begin_time='2022-06-08 09:20:06' -v end_time='2022-06-08 10:30:10'
\x off
\x on

\set btime :begin_time
\set etime :end_time

select min(snap_id) as bsnap
  from perfstat.snap
  where snap_time >= :'btime' \gset
select max(snap_id) as esnap
  from perfstat.snap
  where snap_time <= :'etime' \gset
\qecho bsnap :bsnap
\qecho esnap :esnap

\x off
\pset pager off
\pset footer off
\pset tuples_only
\o AWR_BATCH.SQL
select '\set instance_name ' || server_id || ' \i awrrpt_no_input.sql'
  from aurora_replica_status();
\o
\pset tuples_only off

\i AWR_BATCH.SQL
