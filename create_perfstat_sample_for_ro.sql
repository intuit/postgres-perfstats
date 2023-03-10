-- Create new sample

insert into perfstat.pg_stat_activity_sample
  select now(), ':reader_instance_name', c.*
  from perfstat.pg_stat_activity_:reader_instance_name_us c
  where c.datid = (select oid from pg_database where datname = current_database());
