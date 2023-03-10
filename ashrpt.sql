\pset footer off
\prompt 'Enter begin time (yyyy-mm-dd hh24:mi:ss): ' bsample
\prompt 'Enter end time (yyyy-mm-dd hh24:mi:ss): ' esample

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

select to_char(to_timestamp(:'bsample', 'yyyy-mm-dd hh24:mi:ss'), 'hh24mi') as bhourmin \gset
select to_char(to_timestamp(:'esample', 'yyyy-mm-dd hh24:mi:ss'), 'hh24mi') as ehourmin \gset
\set report ashrpt_:instance_type _:bhourmin _:ehourmin.html

\o :report
\pset format aligned
\pset format html


\x off

\qecho <h1>ASH report for</h1>

select server_id "instance name",
       case session_id when 'MASTER_SESSION_ID' then 'writer' else 'reader' end "instance type",
       current_database() as database
  from aurora_replica_status()
 where server_id = :'instance_name';

select version() as version;


select count(distinct sample_time) sample_count
  from perfstat.pg_stat_activity_sample
  where sample_time > to_timestamp(:'bsample', 'yyyy-mm-dd hh24:mi:ss')
    and sample_time <= to_timestamp(:'esample', 'yyyy-mm-dd hh24:mi:ss') 
    and instance_name = :'instance_name' \gset

select :'bsample' "time begin", :'esample' "time end", :sample_count "total samples"; 

\qecho <h3>Session Count</h3>
select sample_time "sample time", count(*) "session count", sum(case state when 'active' then 1 else 0 end) "active session count"
  from perfstat.pg_stat_activity_sample
  where sample_time > to_timestamp(:'bsample', 'yyyy-mm-dd hh24:mi:ss')
    and sample_time <= to_timestamp(:'esample', 'yyyy-mm-dd hh24:mi:ss') 
    and instance_name = :'instance_name'
  group by sample_time
  order by 1; 

\qecho <h3>Active Session with Wait Event</h3>
select sample_time "sample time", wait_event_type || ':' || wait_event "wait event", count(*) "session count"
  from perfstat.pg_stat_activity_sample
  where sample_time > to_timestamp(:'bsample', 'yyyy-mm-dd hh24:mi:ss')
    and sample_time <= to_timestamp(:'esample', 'yyyy-mm-dd hh24:mi:ss') 
    and state = 'active'
    and wait_event is not null
    and instance_name = :'instance_name'
  group by sample_time, wait_event_type, wait_event
union
select sample_time "sample time", 'CPU' "wait event", count(*) "event count"
  from perfstat.pg_stat_activity_sample
  where sample_time > to_timestamp(:'bsample', 'yyyy-mm-dd hh24:mi:ss')
    and sample_time <= to_timestamp(:'esample', 'yyyy-mm-dd hh24:mi:ss') 
    and state = 'active'
    and wait_event is null
    and instance_name = :'instance_name'
  group by sample_time, wait_event_type, wait_event
order by 1; 

\qecho <h3>Active Session with SQL</h3>
select sample_time "sample time", left(query, 60) query, count(*) "query count"
  from perfstat.pg_stat_activity_sample
  where sample_time > to_timestamp(:'bsample', 'yyyy-mm-dd hh24:mi:ss')
    and sample_time <= to_timestamp(:'esample', 'yyyy-mm-dd hh24:mi:ss') 
    and state = 'active'
    and instance_name = :'instance_name'
  group by sample_time, left(query, 60)
  order by 1; 

\qecho <h3>Top Active Session</h3>
select pid, usename, count(*) "sample count"
  from perfstat.pg_stat_activity_sample
  where sample_time > to_timestamp(:'bsample', 'yyyy-mm-dd hh24:mi:ss')
    and sample_time <= to_timestamp(:'esample', 'yyyy-mm-dd hh24:mi:ss') 
    and state = 'active'
    and instance_name = :'instance_name'
  group by 1, 2 
  order by 3 desc; 

\qecho <h3>Complete List of SQL Text</h3>
select distinct query
  from perfstat.pg_stat_activity_sample
  where sample_time > to_timestamp(:'bsample', 'yyyy-mm-dd hh24:mi:ss')
    and sample_time <= to_timestamp(:'esample', 'yyyy-mm-dd hh24:mi:ss') 
    and wait_event is not null
    and instance_name = :'instance_name'
  order by 1; 

\pset format aligned
\o
\qecho Report :report has been generated

\pset footer on
