-- Create new snap

insert into perfstat.instance_hist 
  select a.*, ':reader_instance_name', b.*
    from (select * from perfstat.snap order by snap_id desc limit 1) a, perfstat.instance_start_time_:reader_instance_name_us b;

insert into perfstat.pg_stat_statements_hist 
  select a.*, ':reader_instance_name', b.*
    from (select * from perfstat.snap order by snap_id desc limit 1) a, perfstat.pg_stat_statements_:reader_instance_name_us b
    where dbid = (select oid from pg_database where datname = current_database());

insert into perfstat.pg_stat_activity_hist
  select a.*, ':reader_instance_name', b.*
    from (select * from perfstat.snap order by snap_id desc limit 1) a, perfstat.pg_stat_activity_:reader_instance_name_us b
    where datid = (select oid from pg_database where datname = current_database());

insert into perfstat.pg_stat_database_hist
  select a.*, ':reader_instance_name', b.*
    from (select * from perfstat.snap order by snap_id desc limit 1) a, perfstat.pg_stat_database_:reader_instance_name_us b
    where datid = (select oid from pg_database where datname = current_database());

insert into perfstat.pg_stat_all_tables_hist
  select a.*, ':reader_instance_name', b.*
    from (select * from perfstat.snap order by snap_id desc limit 1) a, perfstat.pg_stat_all_tables_:reader_instance_name_us b;

insert into perfstat.pg_stat_all_indexes_hist
  select a.*, ':reader_instance_name', b.*
    from (select * from perfstat.snap order by snap_id desc limit 1) a, perfstat.pg_stat_all_indexes_:reader_instance_name_us b;

insert into perfstat.dba_plans_hist
  select a.*, ':reader_instance_name', b.*
    from (select * from perfstat.snap order by snap_id desc limit 1) a, perfstat.dba_plans_:reader_instance_name_us b;

