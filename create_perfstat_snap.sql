-- Create new snap

select partman.run_maintenance('perfstat.snap');
insert into perfstat.snap select coalesce(max(snap_id), 0)+1, now() from perfstat.snap;

select partman.run_maintenance('perfstat.pg_stat_statements_hist');
insert into perfstat.pg_stat_statements_hist 
  select a.*, b.*, c.*
  from (select * from perfstat.snap order by snap_id desc limit 1) a,
       (select server_id from aurora_replica_status() where session_id = 'MASTER_SESSION_ID') b,
        pg_stat_statements c
  where dbid = (select oid from pg_database where datname = current_database());

select partman.run_maintenance('perfstat.instance_hist');
insert into perfstat.instance_hist
  select a.*, b.*, pg_postmaster_start_time()
  from (select * from perfstat.snap order by snap_id desc limit 1) a,
       (select server_id from aurora_replica_status() where session_id = 'MASTER_SESSION_ID') b;

select partman.run_maintenance('perfstat.pg_stat_activity_hist');
insert into perfstat.pg_stat_activity_hist
  select a.*, b.*, c.*
  from (select * from perfstat.snap order by snap_id desc limit 1) a,
       (select server_id from aurora_replica_status() where session_id = 'MASTER_SESSION_ID') b,
       pg_stat_activity c
  where datid = (select oid from pg_database where datname = current_database());

select partman.run_maintenance('perfstat.pg_stat_database_hist');
insert into perfstat.pg_stat_database_hist
  select a.*, b.*, c.*
  from (select * from perfstat.snap order by snap_id desc limit 1) a,
       (select server_id from aurora_replica_status() where session_id = 'MASTER_SESSION_ID') b,
       pg_stat_database c
  where datid = (select oid from pg_database where datname = current_database());

select partman.run_maintenance('perfstat.pg_stat_all_tables_hist');
insert into perfstat.pg_stat_all_tables_hist
  select a.*, b.*, c.*
  from (select * from perfstat.snap order by snap_id desc limit 1) a,
       (select server_id from aurora_replica_status() where session_id = 'MASTER_SESSION_ID') b,
       pg_stat_all_tables c;

select partman.run_maintenance('perfstat.pg_stat_all_indexes_hist');
insert into perfstat.pg_stat_all_indexes_hist
  select a.*, b.*, c.*
  from (select * from perfstat.snap order by snap_id desc limit 1) a,
       (select server_id from aurora_replica_status() where session_id = 'MASTER_SESSION_ID') b,
       pg_stat_all_indexes c;

select partman.run_maintenance('perfstat.dba_plans_hist');
insert into perfstat.dba_plans_hist
  select a.*, b.*, c.*
  from (select * from perfstat.snap order by snap_id desc limit 1) a,
       (select server_id from aurora_replica_status() where session_id = 'MASTER_SESSION_ID') b,
       apg_plan_mgmt.dba_plans c;
