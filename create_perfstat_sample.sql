-- Create new sample

select partman.run_maintenance('perfstat.pg_stat_activity_sample');
insert into perfstat.pg_stat_activity_sample
  select now(), b.*, c.*
  from (select server_id from aurora_replica_status() where session_id = 'MASTER_SESSION_ID') b,
       pg_stat_activity c
  where c.datid = (select oid from pg_database where datname = current_database());
