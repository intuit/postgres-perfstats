\x off
\pset pager off
\pset footer off
select *
  from perfstat.snap
  order by 1;

\pset pager on
\x on

\prompt 'Enter begin snap id: ' bsnap
\prompt 'Enter end snap id: ' esnap

\x off
select server_id "instance name",
       case session_id when 'MASTER_SESSION_ID' then 'writer' else 'reader' end "instance type"
  from aurora_replica_status()
  where session_id = 'MASTER_SESSION_ID'
     or exists (select 'x' from information_schema.foreign_tables where foreign_server_name = replace(server_id, '-', '_'));

select 'Enter instance name(default ' || server_id || '): ' as requesting_instance_name,
       server_id as default_instance_name
  from aurora_replica_status()
    where session_id = 'MASTER_SESSION_ID' \gset

\prompt :requesting_instance_name selected_instance_name 

select case :'selected_instance_name' when '' then :'default_instance_name' else :'selected_instance_name' end as instance_name \gset

\qecho Selected instance :instance_name
\x on

select case session_id when 'MASTER_SESSION_ID' then 'writer' else 'reader' end as instance_type
  from aurora_replica_status()
 where server_id = :'instance_name' \gset

\set ON_ERROR_STOP on

select case count(*) when 0 then true else perfstat.error_generator('The instance was shutdown between snapshots ' || :bsnap || ' and ' || :esnap) end "no instance restarted"
  from perfstat.instance_hist
  where instance_start_time between
    (select snap_time from perfstat.instance_hist where instance_name = :'instance_name' and snap_id = :bsnap) and  
    (select snap_time from perfstat.instance_hist where instance_name = :'instance_name' and snap_id = :esnap);
 
\set report awrrpt_:instance_type _:bsnap _:esnap.html

\o :report 
\pset format aligned
\pset format html

\x off

\qecho <h1>WORKLOAD REPOSITORY report for</h1>

select server_id "instance name",
       case session_id when 'MASTER_SESSION_ID' then 'writer' else 'reader' end "instance type",
       current_database() as database
  from aurora_replica_status()
 where server_id = :'instance_name';

select version() as version;

select b.snap_id "begin snap id",
       b.snap_time "begin snap time",
       e.snap_id "end snap id",
       e.snap_time "end snap time"
  from perfstat.snap b, perfstat.snap e
  where b.snap_id = :bsnap
   and e.snap_id = :esnap;

select round((extract(epoch from (max(b.snap_time) - max(a.snap_time))) / 60)::numeric, 2) as "elapsed time (mins)",
       round((sum((b.total_exec_time + b.total_plan_time - coalesce(a.total_exec_time + a.total_plan_time, 0))) / 60000)::numeric, 2) as "db time (mins)"
  from perfstat.pg_stat_statements_hist a right join perfstat.pg_stat_statements_hist b
    on (a.instance_name = b.instance_name and a.userid = b.userid and a.dbid = b.dbid and a.queryid = b.queryid and a.query = b.query and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name';


select round((sum((b.total_exec_time + b.total_plan_time - coalesce(a.total_exec_time + a.total_plan_time, 0))))::numeric, 2) as total_exec_time
  from perfstat.pg_stat_statements_hist a right join perfstat.pg_stat_statements_hist b
    on (a.instance_name = b.instance_name and a.userid = b.userid and a.dbid = b.dbid and a.queryid = b.queryid and a.query = b.query and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name' \gset


select round(extract(epoch from (b.snap_time - a.snap_time))::numeric, 2) as elapsed_sec,
       case ((b.xact_commit - coalesce(a.xact_commit, 0)) + (b.xact_rollback - coalesce(a.xact_rollback, 0))) when 0 then 1 
          else ((b.xact_commit - coalesce(a.xact_commit, 0)) + (b.xact_rollback - coalesce(a.xact_rollback, 0))) end as total_xact
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.instance_name = b.instance_name and a.datid = b.datid and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name' \gset


\qecho <h2>Report Summary</h2>

\qecho <h4>Instance Statistics</h4>

select a.metric_name || ' (percent)' metric,
      round(avg(a.value)::numeric, 2) average,
      round(max(b.value)::numeric, 2) maximum,
      round(min(c.value)::numeric, 2) minimum 
  from perfstat.host_stat_hist a, perfstat.host_stat_hist b, perfstat.host_stat_hist c
  where a.snap_id between :bsnap and :esnap
   and b.snap_id between :bsnap and :esnap
   and c.snap_id between :bsnap and :esnap 
   and a.statistics = 'Average'
   and b.statistics = 'Maximum'
   and c.statistics = 'Minimum'
   and a.metric_name = b.metric_name
   and a.metric_name = c.metric_name
   and a.metric_name = 'CPUUtilization'
   and a.instance_name = b.instance_name 
   and a.instance_name = c.instance_name 
   and a.instance_name = :'instance_name'
  group by a.metric_name, b.metric_name, c.metric_name
union
select a.metric_name || ' (milliseconds)' metric,
      round((avg(a.value) * 1000)::numeric, 2) average,
      round((max(b.value) * 1000)::numeric, 2) maximum,
      round((min(c.value) * 1000)::numeric, 2) minimum 
  from perfstat.host_stat_hist a, perfstat.host_stat_hist b, perfstat.host_stat_hist c
  where a.snap_id between :bsnap and :esnap
   and b.snap_id between :bsnap and :esnap
   and c.snap_id between :bsnap and :esnap 
   and a.statistics = 'Average'
   and b.statistics = 'Maximum'
   and c.statistics = 'Minimum'
   and a.metric_name = b.metric_name
   and a.metric_name = c.metric_name
   and a.metric_name like '%Latency'
   and a.instance_name = b.instance_name 
   and a.instance_name = c.instance_name 
   and a.instance_name = :'instance_name'
  group by a.metric_name, b.metric_name, c.metric_name
union
select a.metric_name || ' (mb)' metric,
      round((avg(a.value) / 1048576)::numeric, 2) average,
      round((max(b.value) / 1048576)::numeric, 2) maximum,
      round((min(c.value) / 1048576)::numeric, 2) minimum 
  from perfstat.host_stat_hist a, perfstat.host_stat_hist b, perfstat.host_stat_hist c
  where a.snap_id between :bsnap and :esnap
   and b.snap_id between :bsnap and :esnap
   and c.snap_id between :bsnap and :esnap 
   and a.statistics = 'Average'
   and b.statistics = 'Maximum'
   and c.statistics = 'Minimum'
   and a.metric_name = b.metric_name
   and a.metric_name = c.metric_name
   and a.metric_name = 'FreeableMemory'
   and a.instance_name = b.instance_name
   and a.instance_name = c.instance_name
   and a.instance_name = :'instance_name'
  group by a.metric_name, b.metric_name, c.metric_name
union
select a.metric_name || ' (count/second)'  metric,
      round(avg(a.value)::numeric, 2) average,
      round(max(b.value)::numeric, 2) maximum,
      round(min(c.value)::numeric, 2) minimum 
  from perfstat.host_stat_hist a, perfstat.host_stat_hist b, perfstat.host_stat_hist c
  where a.snap_id between :bsnap and :esnap
   and b.snap_id between :bsnap and :esnap
   and c.snap_id between :bsnap and :esnap 
   and a.statistics = 'Average'
   and b.statistics = 'Maximum'
   and c.statistics = 'Minimum'
   and a.metric_name = b.metric_name
   and a.metric_name = c.metric_name
   and a.metric_name like '%IOPS'
   and a.instance_name = b.instance_name
   and a.instance_name = c.instance_name
   and a.instance_name = :'instance_name'
  group by a.metric_name, b.metric_name, c.metric_name
union
select a.metric_name || ' (mb/second)'  metric,
      round((avg(a.value) / 1048576)::numeric, 2) average,
      round((max(b.value) / 1048576)::numeric, 2) maximum,
      round((min(c.value) / 1048576)::numeric, 2) minimum 
  from perfstat.host_stat_hist a, perfstat.host_stat_hist b, perfstat.host_stat_hist c
  where a.snap_id between :bsnap and :esnap
   and b.snap_id between :bsnap and :esnap
   and c.snap_id between :bsnap and :esnap 
   and a.statistics = 'Average'
   and b.statistics = 'Maximum'
   and c.statistics = 'Minimum'
   and a.metric_name = b.metric_name
   and a.metric_name = c.metric_name
   and a.metric_name like '%Throughput'
   and a.instance_name = b.instance_name
   and a.instance_name = c.instance_name
   and a.instance_name = :'instance_name'
  group by a.metric_name, b.metric_name, c.metric_name
  order by 1;

\qecho <h4>Database Load Profile</h4>
\t off 

select 'xact_commit' as metric,
      round((b.xact_commit - coalesce(a.xact_commit, 0)::numeric) / :elapsed_sec::numeric, 2) "per second",
      round((b.xact_commit - coalesce(a.xact_commit, 0)::numeric) / :total_xact::numeric, 2) "per transaction" 
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.instance_name = b.instance_name and a.datid = b.datid and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
union
select 'xact_rollback' as metric,
      round((b.xact_rollback - coalesce(a.xact_rollback, 0)::numeric) / :elapsed_sec::numeric, 2) "per second",
      round((b.xact_rollback - coalesce(a.xact_rollback, 0)::numeric) / :total_xact::numeric, 2) "per transaction"
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.instance_name = b.instance_name and a.datid = b.datid and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
union
select 'blks_read' as metric,
      round((b.blks_read - coalesce(a.blks_read, 0)::numeric) / :elapsed_sec::numeric, 2) "per second",
      round((b.blks_read - coalesce(a.blks_read, 0)::numeric) / :total_xact::numeric, 2) "per transaction"
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.instance_name = b.instance_name and a.datid = b.datid and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
union
select 'blks_hit' as metric,
      round((b.blks_hit - coalesce(a.blks_hit, 0)::numeric) / :elapsed_sec::numeric, 2) "per second",
      round((b.blks_hit - coalesce(a.blks_hit, 0)::numeric) / :total_xact::numeric, 2) "per transaction"
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.instance_name = b.instance_name and a.datid = b.datid and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
union
select 'tup_returned' as metric,
      round((b.tup_returned - coalesce(a.tup_returned, 0)::numeric) / :elapsed_sec::numeric, 2) "per second",
      round((b.tup_returned - coalesce(a.tup_returned, 0)::numeric) / :total_xact::numeric, 2) "per transaction"
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.instance_name = b.instance_name and a.datid = b.datid and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
union
select 'tup_fetched' as metric,
      round((b.tup_fetched - coalesce(a.tup_fetched, 0)::numeric) / :elapsed_sec::numeric, 2) "per second",
      round((b.tup_fetched - coalesce(a.tup_fetched, 0)::numeric) / :total_xact::numeric, 2) "per transaction"
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.instance_name = b.instance_name and a.datid = b.datid and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
union
select 'tup_inserted' as metric,
      round((b.tup_inserted - coalesce(a.tup_inserted, 0)::numeric) / :elapsed_sec::numeric, 2) "per second",
      round((b.tup_inserted - coalesce(a.tup_inserted, 0)::numeric) / :total_xact::numeric, 2) "per transaction"
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.instance_name = b.instance_name and a.datid = b.datid and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
union
select 'tup_updated' as metric,
      round((b.tup_updated - coalesce(a.tup_updated, 0)::numeric) / :elapsed_sec::numeric, 2) "per second",
      round((b.tup_updated - coalesce(a.tup_updated, 0)::numeric) / :total_xact::numeric, 2) "per transaction"
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.instance_name = b.instance_name and a.datid = b.datid and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
union
select 'tup_deleted' as metric,
      round((b.tup_deleted - coalesce(a.tup_deleted, 0)::numeric) / :elapsed_sec::numeric, 2) "per second",
      round((b.tup_deleted - coalesce(a.tup_deleted, 0)::numeric) / :total_xact::numeric, 2) "per transaction"
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.instance_name = b.instance_name and a.datid = b.datid and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
union
select 'temp_files' as metric,
      round((b.temp_files - coalesce(a.temp_files, 0)::numeric) / :elapsed_sec::numeric, 2) "per second",
      round((b.temp_files - coalesce(a.temp_files, 0)::numeric) / :total_xact::numeric, 2) "per transaction"
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.instance_name = b.instance_name and a.datid = b.datid and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
union
select 'temp_bytes' as metric,
      round((b.temp_bytes - coalesce(a.temp_bytes, 0)::numeric) / :elapsed_sec::numeric, 2) "per second",
      round((b.temp_bytes - coalesce(a.temp_bytes, 0)::numeric) / :total_xact::numeric, 2) "per transaction"
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.instance_name = b.instance_name and a.datid = b.datid and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
union
select 'deadlocks' as metric,
      round((b.deadlocks - coalesce(a.deadlocks, 0)::numeric) / :elapsed_sec::numeric, 2) "per second",
      round((b.deadlocks - coalesce(a.deadlocks, 0)::numeric) / :total_xact::numeric, 2) "per transaction"
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.instance_name = b.instance_name and a.datid = b.datid and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
union
select 'blk_read_time' as metric,
      trunc(((b.blk_read_time - coalesce(a.blk_read_time, 0)::numeric) / :elapsed_sec::numeric)::numeric, 2) "per second",
      trunc(((b.blk_read_time - coalesce(a.blk_read_time, 0)::numeric) / :total_xact::numeric)::numeric, 2) "per transaction"
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.instance_name = b.instance_name and a.datid = b.datid and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
union
select 'blk_write_time' as metric,
      trunc(((b.blk_write_time - coalesce(a.blk_write_time, 0)::numeric) / :elapsed_sec::numeric)::numeric, 2) "per second",
      trunc(((b.blk_write_time - coalesce(a.blk_write_time, 0)::numeric) / :total_xact::numeric)::numeric, 2) "per transaction"
  from perfstat.pg_stat_database_hist a right join perfstat.pg_stat_database_hist b
    on (a.instance_name = b.instance_name and a.datid = b.datid and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
union
select 'calls' as metric, 
       round((sum(b.calls - coalesce(a.calls, 0))::numeric) / :elapsed_sec::numeric, 2) "per second",
       round((sum(b.calls - coalesce(a.calls, 0))::numeric) / :total_xact::numeric, 2) "per transaction"
  from perfstat.pg_stat_statements_hist a right join perfstat.pg_stat_statements_hist b
    on (a.instance_name = b.instance_name and a.dbid = b.dbid and a.userid = b.userid and a.queryid = b.queryid and a.query = b.query and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name' 
union
select 'db_time' as metric, 
       round((sum(b.total_exec_time + b.total_plan_time - coalesce(a.total_exec_time + a.total_plan_time, 0))::numeric) / :elapsed_sec::numeric, 2) "per second",
       round((sum(b.total_exec_time + b.total_plan_time - coalesce(a.total_exec_time + a.total_plan_time, 0))::numeric) / :total_xact::numeric, 2) "per transaction"
  from perfstat.pg_stat_statements_hist a right join perfstat.pg_stat_statements_hist b
    on (a.instance_name = b.instance_name and a.dbid = b.dbid and a.userid = b.userid and a.queryid = b.queryid and a.query = b.query and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name' 
order by 1;  

\qecho <h5>all times above are in milliseconds</h5>

select count(distinct sample_time) sample_count
  from perfstat.pg_stat_activity_sample
  where sample_time > (select snap_time from perfstat.snap b where b.snap_id = :bsnap)
    and sample_time <= (select snap_time from perfstat.snap e where e.snap_id = :esnap)
    and instance_name = :'instance_name' \gset

\qecho <h4>Database Top Wait Events</h4>
select wait_event_type || ':' || wait_event "wait event", round(count(*)::numeric / :sample_count::numeric, 2) "count"
  from perfstat.pg_stat_activity_sample 
  where sample_time > (select snap_time from perfstat.snap b where b.snap_id = :bsnap)
    and sample_time <= (select snap_time from perfstat.snap e where e.snap_id = :esnap) 
    and wait_event is not null
    and instance_name = :'instance_name'
  group by wait_event_type, wait_event 
union
select 'CPU' "wait event", round(count(*)::numeric / :sample_count::numeric, 2) "count"
  from perfstat.pg_stat_activity_sample
  where sample_time > (select snap_time from perfstat.snap b where b.snap_id = :bsnap)
    and sample_time <= (select snap_time from perfstat.snap e where e.snap_id = :esnap)
    and wait_event is null
    and state = 'active'
    and instance_name = :'instance_name'
  group by wait_event_type, wait_event
order by 2 desc
limit 10;

\qecho <h5>based on :sample_count samples</h5>

\qecho <h4>Database Session State</h4>
select state "session state", round(count(*)::numeric / :sample_count::numeric, 2) "count",
       round(extract(epoch from (sum(current_timestamp - state_change)))::numeric / :sample_count::numeric, 2) "seconds spent"
  from perfstat.pg_stat_activity_sample 
  where sample_time > (select snap_time from perfstat.snap b where b.snap_id = :bsnap)
    and sample_time <= (select snap_time from perfstat.snap e where e.snap_id = :esnap) 
    and state is not null
    and instance_name = :'instance_name'
  group by state 
  order by 2 desc
  limit 10;
\qecho <h5>based on :sample_count samples</h5>

--select to_char(sample_time, 'yyyy-mm-dd-hh-mi'), count(*) 
--  from perfstat.pg_stat_activity_sample 
--  where sample_time > (select snap_time from perfstat.snap b where b.snap_id = :bsnap)
--    and sample_time <= (select snap_time from perfstat.snap e where e.snap_id = :esnap)
--    and instance_name = :'instance_name'
--  group by to_char(sample_time, 'yyyy-mm-dd-hh-mi')
--  order by 1; 

\qecho <h2>Main Report</h2>

\qecho <h5>
\qecho <ul>
\qecho <li><a href="#SQL Statistics">SQL Statistics</a></li>
\qecho <li><a href="#Object Statistics">Object Statistics</a></li>
\qecho </ul>
\qecho </h5>

\qecho <h3><a name="SQL Statistics"></a>SQL Statistics</h3>
\qecho <h5>
\qecho <ul>
\qecho <li><a href="#SQL ordered by Total Time">SQL ordered by Total Time</a></li>
\qecho <li><a href="#SQL ordered by I/O Time">SQL ordered by I/O Time</a></li>
\qecho <li><a href="#SQL ordered by Logical Reads">SQL ordered by Logical Reads</a></li>
\qecho <li><a href="#SQL ordered by Reads">SQL ordered by Reads</a></li>
\qecho </ul>
\qecho </h5>

\qecho <h4><a name="SQL ordered by Total Time"></a>SQL ordered by Total Time</h4>

select 
       round((b.total_exec_time + b.total_plan_time - coalesce(a.total_exec_time + a.total_plan_time, 2))::numeric, 2) "total time",
       b.calls - coalesce(a.calls, 0) calls,
       round((b.blk_read_time - coalesce(a.blk_read_time, 0))::numeric, 2) "blk read time",
       --round((b.blk_write_time - coalesce(a.blk_write_time, 0))::numeric, 2) blk_write_time,
       b.rows - coalesce(a.rows, 0) "rows",
       round(((b.total_exec_time + b.total_plan_time - coalesce(a.total_exec_time + a.total_plan_time, 2))::numeric / :total_exec_time) * 100, 2) "%total",
       round(((b.total_exec_time + b.total_plan_time - coalesce(a.total_exec_time + a.total_plan_time, 0))::numeric / case (b.calls - coalesce(a.calls, 0)) when 0 then 1 else (b.calls - coalesce(a.calls, 0)) end)::numeric, 2) "avg time",
       round(((b.blk_read_time - coalesce(a.blk_read_time, 0))::numeric / case (b.calls - coalesce(a.calls, 0)) when 0 then 1 else (b.calls - coalesce(a.calls, 0)) end)::numeric, 2) "avg blk read time",
       round(((b.rows - coalesce(a.rows, 0))::numeric / case (b.calls - coalesce(a.calls, 0)) when 0 then 1 else (b.calls - coalesce(a.calls, 0)) end)::numeric, 2) "avg rows",
       '<a href="#' || b.queryid || '">' || b.queryid queryid,
       left(b.query, 60) query
  from perfstat.pg_stat_statements_hist a right join perfstat.pg_stat_statements_hist b
    on (a.instance_name = b.instance_name and a.dbid = b.dbid and a.userid = b.userid and a.queryid = b.queryid and a.query = b.query and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name' 
  and b.total_exec_time + b.total_plan_time - coalesce(a.total_exec_time + a.total_plan_time, 2) > 0
  order by b.total_exec_time + b.total_plan_time - coalesce(a.total_exec_time + a.total_plan_time, 0) desc
  limit 30;

\qecho <h5>all times above are in milliseconds</h5>

\qecho <h4><a name="SQL ordered by I/O Time"></a>SQL ordered by I/O Time</h4>
select 
       round((b.blk_read_time - coalesce(a.blk_read_time, 0))::numeric, 2) "blk read time",
       --round((b.blk_write_time - coalesce(a.blk_write_time, 0))::numeric, 2) blk_write_time,
       round((b.total_exec_time + b.total_plan_time - coalesce(a.total_exec_time + a.total_plan_time, 2))::numeric, 2) "total time",
       b.calls - coalesce(a.calls, 0) calls,
       b.rows - coalesce(a.rows, 0) "rows",
       round(((b.blk_read_time - coalesce(a.blk_read_time, 0))::numeric / case (b.calls - coalesce(a.calls, 0)) when 0 then 1 else (b.calls - coalesce(a.calls, 0)) end)::numeric, 2) "avg block read time",
       round(((b.total_exec_time + b.total_plan_time - coalesce(a.total_exec_time + a.total_plan_time, 0))::numeric / case (b.calls - coalesce(a.calls, 0)) when 0 then 1 else (b.calls - coalesce(a.calls, 0)) end)::numeric, 2) "avg time",
       round(((b.rows - coalesce(a.rows, 0))::numeric / case (b.calls - coalesce(a.calls, 0)) when 0 then 1 else (b.calls - coalesce(a.calls, 0)) end)::numeric, 2) "avg rows",
       '<a href="#' || b.queryid || '">' || b.queryid queryid,
       left(b.query, 60) query
   from perfstat.pg_stat_statements_hist a right join perfstat.pg_stat_statements_hist b
     on (a.instance_name = b.instance_name and a.dbid = b.dbid and a.userid = b.userid and a.queryid = b.queryid and a.query = b.query and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name' 
    and b.blk_read_time - coalesce(a.blk_read_time, 0) > 0
  order by (b.blk_read_time - coalesce(a.blk_read_time, 0)) + (b.blk_write_time - coalesce(a.blk_write_time, 0)) desc
  limit 30;

\qecho <h5>all times above are in milliseconds</h5>

\qecho <h4><a name="SQL ordered by Logical Reads"></a>SQL ordered by Logical Reads</h4>
select 
       round((b.shared_blks_read - coalesce(a.shared_blks_read, 0))::numeric, 2) +
       round((b.shared_blks_hit - coalesce(a.shared_blks_hit, 0))::numeric, 2) "shared blks read & hit",
       round((b.local_blks_read - coalesce(a.local_blks_read, 0))::numeric, 2) + 
       round((b.local_blks_hit - coalesce(a.local_blks_hit, 0))::numeric, 2) "local blks read & hit",
       round((b.temp_blks_read - coalesce(a.temp_blks_read, 0))::numeric, 2) "temp blks read",
       b.calls - coalesce(a.calls, 0) calls,
       round(((b.shared_blks_read - coalesce(a.shared_blks_read, 0)) + (b.shared_blks_hit - coalesce(a.shared_blks_hit, 0)))::numeric / (case (b.calls - coalesce(a.calls, 0)) when 0 then 1 else (b.calls - coalesce(a.calls, 0)) end)::numeric, 2) "avg shared blks read & hit",
       round(((b.local_blks_read - coalesce(a.local_blks_read, 0)) + (b.local_blks_hit - coalesce(a.local_blks_hit, 0)))::numeric / (case (b.calls - coalesce(a.calls, 0)) when 0 then 1 else (b.calls - coalesce(a.calls, 0)) end)::numeric, 2) "avg local blks read & hit",
       --round(((b.temp_blks_read - coalesce(a.temp_blks_read, 0))::numeric / case (b.calls - coalesce(a.calls, 0)) when 0 then 1 else (b.calls - coalesce(a.calls, 0)) end)::numeric, 2) "avg temp blks read",
       round(((b.rows - coalesce(a.rows, 0))::numeric / case (b.calls - coalesce(a.calls, 0)) when 0 then 1 else (b.calls - coalesce(a.calls, 0)) end)::numeric, 2) "avg rows",
       '<a href="#' || b.queryid || '">' || b.queryid queryid,
       left(b.query, 60) query
  from perfstat.pg_stat_statements_hist a right join perfstat.pg_stat_statements_hist b
    on (a.instance_name = b.instance_name and a.dbid = b.dbid and a.userid = b.userid and a.queryid = b.queryid and a.query = b.query and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name' 
    and (b.shared_blks_read - coalesce(a.shared_blks_read, 0)) 
      + (b.shared_blks_hit - coalesce(a.shared_blks_hit, 0)) 
      + (b.local_blks_read - coalesce(a.local_blks_read, 0))
      + (b.local_blks_hit - coalesce(a.local_blks_hit, 0))
      + (b.temp_blks_read - coalesce(a.temp_blks_read, 0)) > 0
  order by (b.shared_blks_read - coalesce(a.shared_blks_read, 0)) 
         + (b.shared_blks_hit - coalesce(a.shared_blks_hit, 0)) 
         + (b.local_blks_read - coalesce(a.local_blks_read, 0))
         + (b.local_blks_hit - coalesce(a.local_blks_hit, 0))
         + (b.temp_blks_read - coalesce(a.temp_blks_read, 0)) desc
  limit 30;

\qecho <h5>all times above are in milliseconds</h5>

\qecho <h4><a name="SQL ordered by Reads"></a>SQL ordered by Reads</h4>
select 
       round((b.shared_blks_read - coalesce(a.shared_blks_read, 0))::numeric, 2) "shared blks read",
       round((b.shared_blks_hit - coalesce(a.shared_blks_hit, 0))::numeric, 2) "shared blks hit",
       round((b.local_blks_read - coalesce(a.local_blks_read, 0))::numeric, 2) "local blks read",
       round((b.local_blks_hit - coalesce(a.local_blks_hit, 0))::numeric, 2) "local blks hit",
       round((b.temp_blks_read - coalesce(a.temp_blks_read, 0))::numeric, 2) "temp blks read",
       b.calls - coalesce(a.calls, 0) calls,
       round(((b.shared_blks_read - coalesce(a.shared_blks_read, 0))::numeric / case (b.calls - coalesce(a.calls, 0)) when 0 then 1 else (b.calls - coalesce(a.calls, 0)) end)::numeric, 2) "avg shared blks read",
       round(((b.local_blks_read - coalesce(a.local_blks_read, 0))::numeric / case (b.calls - coalesce(a.calls, 0)) when 0 then 1 else (b.calls - coalesce(a.calls, 0)) end)::numeric, 2) "avg local blks read",
       --round(((b.temp_blks_read - coalesce(a.temp_blks_read, 0))::numeric / case (b.calls - coalesce(a.calls, 0)) when 0 then 1 else (b.calls - coalesce(a.calls, 0)) end)::numeric, 2) "avg emp blks read",
       round(((b.rows - coalesce(a.rows, 0))::numeric / case (b.calls - coalesce(a.calls, 0)) when 0 then 1 else (b.calls - coalesce(a.calls, 0)) end)::numeric, 2) "avg rows",
       '<a href="#' || b.queryid || '">' || b.queryid queryid,
       left(b.query, 60) query
  from perfstat.pg_stat_statements_hist a right join perfstat.pg_stat_statements_hist b
    on (a.instance_name = b.instance_name and a.dbid = b.dbid and a.userid = b.userid and a.queryid = b.queryid and a.query = b.query and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name' 
    and (b.shared_blks_read - coalesce(a.shared_blks_read, 0)) 
      + (b.local_blks_read - coalesce(a.local_blks_read, 0)) 
      + (b.temp_blks_read - coalesce(a.temp_blks_read, 0)) > 0 
  order by (b.shared_blks_read - coalesce(a.shared_blks_read, 0)) 
         + (b.local_blks_read - coalesce(a.local_blks_read, 0)) 
         + (b.temp_blks_read - coalesce(a.temp_blks_read, 0)) desc
  limit 30;

\qecho <h5>all times above are in milliseconds</h5>

\qecho <h3><a name="Object Statistics"></a>Object Statistics</h3>
\qecho <h5>
\qecho <ul>
\qecho <li><a href="#Table ordered by sequential scans">Table ordered by sequential scans</a></li>
\qecho <li><a href="#Table ordered by rows fetched by sequential">Table ordered by rows fetched by sequential scans</a></li>
\qecho <li><a href="#Table ordered by index scans">Table ordered by index scans</a></li>
\qecho <li><a href="#Table ordered by rows fetched by index scans">Table ordered by rows fetched by index scans</a></li>
\qecho </ul>
\qecho </h5>

\qecho <h4><a name="Table ordered by sequential scans">Table ordered by sequential scans</h4>
select b.schemaname "schema",
       b.relname "table", 
       sum(b.seq_scan - coalesce(a.seq_scan, 0)) "seq scan",
       sum(b.seq_tup_read - coalesce(a.seq_tup_read, 0)) "seq tup read",
       sum(b.idx_scan - coalesce(a.idx_scan, 0)) "idx scan",
       sum(b. idx_tup_fetch - coalesce(a.idx_tup_fetch, 0)) "idx tup fetch",
       sum(b.n_tup_ins - coalesce(a.n_tup_ins, 0)) "tup ins",
       sum(b.n_tup_upd - coalesce(a.n_tup_upd, 0)) "tup upd",
       sum(b.n_tup_del - coalesce(a.n_tup_del, 0)) "tup del",
       sum(b.n_tup_hot_upd - coalesce(a.n_tup_hot_upd, 0)) "tup hot upd",
       sum(b.n_live_tup - coalesce(a.n_live_tup, 0)) "live tup",
       sum(b.n_dead_tup - coalesce(a.n_dead_tup, 0)) "dead tup",
       sum(b.vacuum_count - coalesce(a.vacuum_count, 0)) "vacuum count",
       sum(b.autovacuum_count - coalesce(a.autovacuum_count, 0)) "autovacuum count",
       sum(b.analyze_count - coalesce(a.analyze_count, 0)) "analyze count",
       sum(b.autoanalyze_count - coalesce(a.autoanalyze_count, 0)) "autoanalyze count"
  from perfstat.pg_stat_all_tables_hist a right join perfstat.pg_stat_all_tables_hist b
    on (a.instance_name = b.instance_name and a.schemaname = b.schemaname and a.relname = b.relname and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
    and b.schemaname not in ('pg_catalog', 'information_schema') 
  group by b.schemaname, b.relname 
    order by sum(b.seq_scan - coalesce(a.seq_scan, 0)) desc
  limit 20;

\qecho <h4><a name="Table ordered by rows fetched by sequential">Table ordered by rows fetched by sequential scans</h4>
select b.schemaname "schema",
       b.relname "table", 
       sum(b.seq_scan - coalesce(a.seq_scan, 0)) "seq scan",
       sum(b.seq_tup_read - coalesce(a.seq_tup_read, 0)) "seq tup read",
       sum(b.idx_scan - coalesce(a.idx_scan, 0)) idx_scan,
       sum(b. idx_tup_fetch - coalesce(a.idx_tup_fetch, 0)) "idx tup fetch",
       sum(b.n_tup_ins - coalesce(a.n_tup_ins, 0)) "tup ins",
       sum(b.n_tup_upd - coalesce(a.n_tup_upd, 0)) "tup upd",
       sum(b.n_tup_del - coalesce(a.n_tup_del, 0)) "tup del",
       sum(b.n_tup_hot_upd - coalesce(a.n_tup_hot_upd, 0)) "tup hot upd",
       sum(b.n_live_tup - coalesce(a.n_live_tup, 0)) "live tup",
       sum(b.n_dead_tup - coalesce(a.n_dead_tup, 0)) "dead tup",
       sum(b.vacuum_count - coalesce(a.vacuum_count, 0)) "vacuum count",
       sum(b.autovacuum_count - coalesce(a.autovacuum_count, 0)) "autovacuum count",
       sum(b.analyze_count - coalesce(a.analyze_count, 0)) "analyze count",
       sum(b.autoanalyze_count - coalesce(a.autoanalyze_count, 0)) "autoanalyze count"
  from perfstat.pg_stat_all_tables_hist a right join perfstat.pg_stat_all_tables_hist b
    on (a.instance_name = b.instance_name and a.schemaname = b.schemaname and a.relname = b.relname and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
    and b.schemaname not in ('pg_catalog', 'information_schema') 
  group by b.schemaname, b.relname 
    order by sum(b.seq_tup_read - coalesce(a.seq_tup_read, 0)) desc
  limit 20;

\qecho <h4><a name="Table ordered by index scans">Table ordered by index scans</h4>
select b.schemaname "schema",
       b.relname "table", 
       sum(b.seq_scan - coalesce(a.seq_scan, 0)) "seq scan",
       sum(b.seq_tup_read - coalesce(a.seq_tup_read, 0)) "seq tup read",
       sum(b.idx_scan - coalesce(a.idx_scan, 0)) "idx scan",
       sum(b.idx_tup_fetch - coalesce(a.idx_tup_fetch, 0)) "idx tup fetch",
       sum(b.n_tup_ins - coalesce(a.n_tup_ins, 0)) "tup ins",
       sum(b.n_tup_upd - coalesce(a.n_tup_upd, 0)) "tup upd",
       sum(b.n_tup_del - coalesce(a.n_tup_del, 0)) "tup del",
       sum(b.n_tup_hot_upd - coalesce(a.n_tup_hot_upd, 0)) "tup hot upd",
       sum(b.n_live_tup - coalesce(a.n_live_tup, 0)) "live tup",
       sum(b.n_dead_tup - coalesce(a.n_dead_tup, 0)) "dead tup",
       sum(b.vacuum_count - coalesce(a.vacuum_count, 0)) "vacuum count",
       sum(b.autovacuum_count - coalesce(a.autovacuum_count, 0)) "autovacuum count",
       sum(b.analyze_count - coalesce(a.analyze_count, 0)) "analyze count",
       sum(b.autoanalyze_count - coalesce(a.autoanalyze_count, 0)) "autoanalyze count"
  from perfstat.pg_stat_all_tables_hist a right join perfstat.pg_stat_all_tables_hist b
    on (a.instance_name = b.instance_name and a.schemaname = b.schemaname and a.relname = b.relname and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
    and b.schemaname not in ('pg_catalog', 'information_schema') 
    and b.idx_scan is not null
  group by b.schemaname, b.relname 
    order by sum(b.idx_scan - coalesce(a.idx_scan, 0)) desc
  limit 20;

\qecho <h4><a name="Table ordered by rows fetched by index scans">Table ordered by rows fetched by index scans</h4>
select b.schemaname "schema",
       b.relname "table", 
       sum(b.seq_scan - coalesce(a.seq_scan, 0)) "seq scan",
       sum(b.seq_tup_read - coalesce(a.seq_tup_read, 0)) "seq tup read",
       sum(b.idx_scan - coalesce(a.idx_scan, 0)) "idx scan",
       sum(b.idx_tup_fetch - coalesce(a.idx_tup_fetch, 0)) "idx tup fetch",
       sum(b.n_tup_ins - coalesce(a.n_tup_ins, 0)) "tup ins",
       sum(b.n_tup_upd - coalesce(a.n_tup_upd, 0)) "tup upd",
       sum(b.n_tup_del - coalesce(a.n_tup_del, 0)) "tup del",
       sum(b.n_tup_hot_upd - coalesce(a.n_tup_hot_upd, 0)) "tup hot upd",
       sum(b.n_live_tup - coalesce(a.n_live_tup, 0)) "live tup",
       sum(b.n_dead_tup - coalesce(a.n_dead_tup, 0)) "dead tup",
       sum(b.vacuum_count - coalesce(a.vacuum_count, 0)) "vacuum count",
       sum(b.autovacuum_count - coalesce(a.autovacuum_count, 0)) "autovacuum count",
       sum(b.analyze_count - coalesce(a.analyze_count, 0)) "analyze count",
       sum(b.autoanalyze_count - coalesce(a.autoanalyze_count, 0)) "autoanalyze count"
  from perfstat.pg_stat_all_tables_hist a right join perfstat.pg_stat_all_tables_hist b
    on (a.instance_name = b.instance_name and a.schemaname = b.schemaname and a.relname = b.relname and a.snap_id = :bsnap and a.instance_name = :'instance_name')
  where b.snap_id = :esnap and b.instance_name = :'instance_name'
    and b.schemaname not in ('pg_catalog', 'information_schema') 
    and b.idx_tup_fetch is not null
  group by b.schemaname, b.relname 
    order by sum(b.idx_scan - coalesce(a.idx_scan, 0)) desc
  limit 20;

\qecho <h4>Complete List of SQL Text</h4>
select '<a name="' || b.queryid || '">' || b.queryid as queryid, b.query
  from perfstat.pg_stat_statements_hist a right join perfstat.pg_stat_statements_hist b
    on (a.instance_name = b.instance_name and a.userid = b.userid and a.dbid = b.dbid and a.queryid = b.queryid and a.query = b.query and a.snap_id = :bsnap)
 where b.calls - coalesce(a.calls, 0) != 0
   and b.snap_id = :esnap
    and b.instance_name = :'instance_name'
  order by 1;

\pset format aligned 
\o
\qecho Report :report has been generated

\o format.sh
\qecho sed -i -e "s/&lt;/</g" :report
\qecho sed -i -e "s/&gt;/>/g" :report
\qecho 'sed -i -e "s/&quot;/\\"/g"' :report
\qecho rm :report-e
\o
\! chmod +x format.sh
\! ./format.sh
\! rm format.sh

\pset footer on
