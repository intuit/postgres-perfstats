create schema if not exists partman;
create extension if not exists pg_partman with schema partman;

create schema if not exists perfstat;

-- Create the table perfstat.snap
drop table if exists perfstat.snap;
delete from partman.part_config where parent_table = 'perfstat.snap';
drop table if exists partman.template_perfstat_snap;

create table perfstat.snap (snap_id integer, snap_time timestamp with time zone) partition by range (snap_time);
alter table perfstat.snap add constraint snap_pk primary key (snap_id, snap_time);

select partman.create_parent( p_parent_table => 'perfstat.snap',
 p_control => 'snap_time',
 p_type => 'native',
 p_interval=> 'daily',
 p_premake => 1);

update partman.part_config set
    infinite_time_partitions = true,
    retention = '90 days',
    retention_keep_table=false
  where parent_table = 'perfstat.snap';

-- Create the table perfstat.instance_hist
drop table if exists perfstat.instance_hist;
delete from partman.part_config where parent_table = 'perfstat.instance_hist';
drop table if exists partman.template_perfstat.instance_hist;

create table perfstat.instance_hist (
  snap_id integer,
  snap_time timestamp with time zone,
  instance_name character varying(100),
  instance_start_time timestamp with time zone) partition by range (snap_time);
alter table perfstat.instance_hist add constraint instance_hist_pk primary key (snap_id, snap_time, instance_name);

select partman.create_parent( p_parent_table => 'perfstat.instance_hist',
 p_control => 'snap_time',
 p_type => 'native',
 p_interval=> 'daily',
 p_premake => 1);

update partman.part_config set
    infinite_time_partitions = true,
    retention = '90 days',
    retention_keep_table=false
  where parent_table = 'perfstat.instance_hist';

-- Create the view perfstat.instance_start_time_view
drop view if exists perfstat.instance_start_time_view;
create view perfstat.instance_start_time_view as select * from pg_postmaster_start_time();

-- Create the table perfstat.pg_stat_statements_hist
drop table if exists perfstat.pg_stat_statements_hist;
delete from partman.part_config where parent_table = 'perfstat.pg_stat_statements_hist';
drop table if exists partman.template_perfstat_pg_stat_statements_hist;

select
  'create table if not exists perfstat.' || relname || '_hist' || E'\n(\n' ||
  E'    snap_id integer,\n' ||
  E'    snap_time timestamp with time zone,\n' ||
  E'    instance_name character varying(100),\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) partition by range (snap_time)'
from (
  select n.nspname, c.relname, a.attname AS column_name,
         pg_catalog.format_type(a.atttypid, a.atttypmod) as type,
         case
           when a.attnotnull then 'NOT NULL'
           else 'NULL'
         end as not_null
   from pg_class c,
        pg_namespace n,
        pg_attribute a,
        pg_type t
   where n.nspname = 'pg_catalog'
     and c.relowner = n.nspowner
     and c.relname = 'pg_stat_statements'
     and a.attnum > 0
     and a.attrelid = c.oid
     and a.atttypid = t.oid
   order by a.attnum
) as tabledefinition
group by nspname, relname; \gexec

alter table perfstat.pg_stat_statements_hist add constraint pg_stat_statements_hist_pk primary key (snap_id, snap_time, userid, dbid, queryid, instance_name);
create index pg_stat_statements_hist_snap_id on perfstat.pg_stat_statements_hist using btree(snap_id);
create index pg_stat_statements_hist_snap_time on perfstat.pg_stat_statements_hist using btree(snap_time);
create index pg_stat_statements_hist_queryid on perfstat.pg_stat_statements_hist using btree(queryid);

select partman.create_parent( p_parent_table => 'perfstat.pg_stat_statements_hist',
 p_control => 'snap_time',
 p_type => 'native',
 p_interval=> 'daily',
 p_premake => 1);

update partman.part_config set
    infinite_time_partitions = true,
    retention = '90 days',
    retention_keep_table=false
  where parent_table = 'perfstat.pg_stat_statements_hist';

-- Create the table perfstat.pg_stat_activity_hist
drop table if exists perfstat.pg_stat_activity_hist;
delete from partman.part_config where parent_table = 'perfstat.pg_stat_activity_hist';
drop table if exists partman.template_perfstat_pg_stat_activity_hist;

select
  'create table if not exists perfstat.' || relname || '_hist' || E'\n(\n' ||
  E'    snap_id integer,\n' ||
  E'    snap_time timestamp with time zone,\n' ||
  E'    instance_name character varying(100),\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) partition by range (snap_time)'
from (
  select n.nspname, c.relname, a.attname AS column_name,
         pg_catalog.format_type(a.atttypid, a.atttypmod) as type,
         case
           when a.attnotnull then 'NOT NULL'
           else 'NULL'
         end as not_null
   from pg_class c,
        pg_namespace n,
        pg_attribute a,
        pg_type t
   where n.nspname = 'pg_catalog'
     and c.relowner = n.nspowner
     and c.relname = 'pg_stat_activity'
     and a.attnum > 0
     and a.attrelid = c.oid
     and a.atttypid = t.oid
   order by a.attnum
) as tabledefinition
group by nspname, relname; \gexec

create index pg_stat_activity_hist_snap_id on perfstat.pg_stat_activity_hist using btree(snap_id);
create index pg_stat_activity_hist_snap_time on perfstat.pg_stat_activity_hist using btree(snap_time);
create index pg_stat_activity_hist_query on perfstat.pg_stat_activity_hist using btree(query);

select partman.create_parent( p_parent_table => 'perfstat.pg_stat_activity_hist',
 p_control => 'snap_time',
 p_type => 'native',
 p_interval=> 'daily',
 p_premake => 1);

update partman.part_config set
    infinite_time_partitions = true,
    retention = '90 days',
    retention_keep_table=false
  where parent_table = 'perfstat.pg_stat_activity_hist';

-- Create the table perfstat.pg_stat_database_hist
drop table if exists perfstat.pg_stat_database_hist;
delete from partman.part_config where parent_table = 'perfstat.pg_stat_database_hist';
drop table if exists partman.template_perfstat_pg_stat_database_hist;

select
  'create table if not exists perfstat.' || relname || '_hist' || E'\n(\n' ||
  E'    snap_id integer,\n' ||
  E'    snap_time timestamp with time zone,\n' ||
  E'    instance_name character varying(100),\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) partition by range (snap_time)'
from (
  select n.nspname, c.relname, a.attname AS column_name,
         pg_catalog.format_type(a.atttypid, a.atttypmod) as type,
         case
           when a.attnotnull then 'NOT NULL'
           else 'NULL'
         end as not_null
   from pg_class c,
        pg_namespace n,
        pg_attribute a,
        pg_type t
   where n.nspname = 'pg_catalog'
     and c.relowner = n.nspowner
     and c.relname = 'pg_stat_database'
     and a.attnum > 0
     and a.attrelid = c.oid
     and a.atttypid = t.oid
   order by a.attnum
) as tabledefinition
group by nspname, relname; \gexec

create index pg_stat_database_hist_snap_id on perfstat.pg_stat_database_hist using btree(snap_id);
create index pg_stat_database_hist_snap_time on perfstat.pg_stat_database_hist using btree(snap_time);

select partman.create_parent( p_parent_table => 'perfstat.pg_stat_database_hist',
 p_control => 'snap_time',
 p_type => 'native',
 p_interval=> 'daily',
 p_premake => 1);

update partman.part_config set
    infinite_time_partitions = true,
    retention = '90 days',
    retention_keep_table=false
  where parent_table = 'perfstat.pg_stat_database_hist';

-- Create the table perfstat.pg_stat_all_tables_hist
drop table if exists perfstat.pg_stat_all_tables_hist;
delete from partman.part_config where parent_table = 'perfstat.pg_stat_all_tables_hist';
drop table if exists partman.template_perfstat_pg_stat_all_tables_hist;

select
  'create table if not exists perfstat.' || relname || '_hist' || E'\n(\n' ||
  E'    snap_id integer,\n' ||
  E'    snap_time timestamp with time zone,\n' ||
  E'    instance_name character varying(100),\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) partition by range (snap_time)'
from (
  select n.nspname, c.relname, a.attname AS column_name,
         pg_catalog.format_type(a.atttypid, a.atttypmod) as type,
         case
           when a.attnotnull then 'NOT NULL'
           else 'NULL'
         end as not_null
   from pg_class c,
        pg_namespace n,
        pg_attribute a,
        pg_type t
   where n.nspname = 'pg_catalog'
     and c.relowner = n.nspowner
     and c.relname = 'pg_stat_all_tables'
     and a.attnum > 0
     and a.attrelid = c.oid
     and a.atttypid = t.oid
   order by a.attnum
) as tabledefinition
group by nspname, relname; \gexec

create index pg_stat_all_tables_hist_snap_id on perfstat.pg_stat_all_tables_hist using btree(snap_id);
create index pg_stat_all_tables_hist_snap_time on perfstat.pg_stat_all_tables_hist using btree(snap_time);

select partman.create_parent( p_parent_table => 'perfstat.pg_stat_all_tables_hist',
 p_control => 'snap_time',
 p_type => 'native',
 p_interval=> 'daily',
 p_premake => 1);

update partman.part_config set
    infinite_time_partitions = true,
    retention = '90 days',
    retention_keep_table=false
  where parent_table = 'perfstat.pg_stat_all_tables_hist';

-- Create the table perfstat.pg_stat_all_indexes_hist
drop table if exists perfstat.pg_stat_all_indexes_hist;
delete from partman.part_config where parent_table = 'perfstat.pg_stat_all_indexes_hist';
drop table if exists partman.template_perfstat_pg_stat_all_indexes_hist;

select
  'create table if not exists perfstat.' || relname || '_hist' || E'\n(\n' ||
  E'    snap_id integer,\n' ||
  E'    snap_time timestamp with time zone,\n' ||
  E'    instance_name character varying(100),\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) partition by range (snap_time)'
from (
  select n.nspname, c.relname, a.attname AS column_name,
         pg_catalog.format_type(a.atttypid, a.atttypmod) as type,
         case
           when a.attnotnull then 'NOT NULL'
           else 'NULL'
         end as not_null
   from pg_class c,
        pg_namespace n,
        pg_attribute a,
        pg_type t
   where n.nspname = 'pg_catalog'
     and c.relowner = n.nspowner
     and c.relname = 'pg_stat_all_indexes'
     and a.attnum > 0
     and a.attrelid = c.oid
     and a.atttypid = t.oid
   order by a.attnum
) as tabledefinition
group by nspname, relname; \gexec

create index pg_stat_all_indexes_hist_snap_id on perfstat.pg_stat_all_indexes_hist using btree(snap_id);
create index pg_stat_all_indexes_hist_snap_time on perfstat.pg_stat_all_indexes_hist using btree(snap_time);

select partman.create_parent( p_parent_table => 'perfstat.pg_stat_all_indexes_hist',
 p_control => 'snap_time',
 p_type => 'native',
 p_interval=> 'daily',
 p_premake => 1);

update partman.part_config set
    infinite_time_partitions = true,
    retention = '90 days',
    retention_keep_table=false
  where parent_table = 'perfstat.pg_stat_all_indexes_hist';

-- Create the table perfstat.dba_plans_hist
drop table if exists perfstat.dba_plans_hist;
delete from partman.part_config where parent_table = 'perfstat.dba_plans_hist';
drop table if exists partman.template_perfstat_dba_plans_hist;

select
  'create table if not exists perfstat.' || relname || '_hist' || E'\n(\n' ||
  E'    snap_id integer,\n' ||
  E'    snap_time timestamp with time zone,\n' ||
  E'    instance_name character varying(100),\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) partition by range (snap_time)'
from (
  select n.nspname, c.relname, a.attname AS column_name,
         pg_catalog.format_type(a.atttypid, a.atttypmod) as type,
         case
           when a.attnotnull then 'NOT NULL'
           else 'NULL'
         end as not_null
   from pg_class c,
        pg_namespace n,
        pg_attribute a,
        pg_type t
   where n.nspname = 'apg_plan_mgmt'
     and c.relowner = n.nspowner
     and c.relname = 'dba_plans'
     and a.attnum > 0
     and a.attrelid = c.oid
     and a.atttypid = t.oid
   order by a.attnum
) as tabledefinition
group by nspname, relname; \gexec

create index dba_plans_hist_snap_id on perfstat.dba_plans_hist using btree(snap_id);
create index dba_plans_hist_snap_time on perfstat.dba_plans_hist using btree(snap_time);
create index dba_plans_hist_sql_hash on perfstat.dba_plans_hist using btree(sql_hash);
create index dba_plans_hist_queryid on perfstat.dba_plans_hist using btree(queryid);

select partman.create_parent( p_parent_table => 'perfstat.dba_plans_hist',
 p_control => 'snap_time',
 p_type => 'native',
 p_interval=> 'daily',
 p_premake => 1);

update partman.part_config set
    infinite_time_partitions = true,
    retention = '90 days',
    retention_keep_table=false
  where parent_table = 'perfstat.dba_plans_hist';

-- Create the table perfstat.host_stat_hist
drop table if exists perfstat.host_stat_hist;
delete from partman.part_config where parent_table = 'perfstat.host_stat_hist';
drop table if exists partman.template_perfstat.host_stat_hist;

create table perfstat.host_stat_hist(
  snap_id integer,
  snap_time timestamp with time zone,
  instance_name character varying(100),
  metric_name character varying(100),
  statistics character varying(100),
  value double precision) partition by range (snap_time);

create index host_stat_hist_snap_id on perfstat.host_stat_hist using btree(snap_id);
create index host_stat_hist_snap_time on perfstat.host_stat_hist using btree(snap_time);

select partman.create_parent( p_parent_table => 'perfstat.host_stat_hist',
 p_control => 'snap_time',
 p_type => 'native',
 p_interval=> 'daily',
 p_premake => 1);

update partman.part_config set
    infinite_time_partitions = true,
    retention = '90 days',
    retention_keep_table=false
  where parent_table = 'perfstat.host_stat_hist';

-- Create the table perfstat.pg_stat_activity_sample
drop table if exists perfstat.pg_stat_activity_sample;
delete from partman.part_config where parent_table = 'perfstat.pg_stat_activity_sample';
drop table if exists partman.template_perfstat_pg_stat_activity_sample;

select
  'create table if not exists perfstat.' || relname || '_sample' || E'\n(\n' ||
  E'    sample_time timestamp with time zone,\n' ||
  E'    instance_name character varying(100),\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) partition by range (sample_time)'
from (
  select n.nspname, c.relname, a.attname AS column_name,
         pg_catalog.format_type(a.atttypid, a.atttypmod) as type,
         case
           when a.attnotnull then 'NOT NULL'
           else 'NULL'
         end as not_null
   from pg_class c,
        pg_namespace n,
        pg_attribute a,
        pg_type t
   where n.nspname = 'pg_catalog'
     and c.relowner = n.nspowner
     and c.relname = 'pg_stat_activity'
     and a.attnum > 0
     and a.attrelid = c.oid
     and a.atttypid = t.oid
   order by a.attnum
) as tabledefinition
group by nspname, relname; \gexec

create index pg_stat_activity_sample_sample_time on perfstat.pg_stat_activity_sample using btree(sample_time);
create index pg_stat_activity_sample_query on perfstat.pg_stat_activity_sample using btree(query);

select partman.create_parent( p_parent_table => 'perfstat.pg_stat_activity_sample',
 p_control => 'sample_time',
 p_type => 'native',
 p_interval=> 'daily',
 p_premake => 1);

update partman.part_config set
    infinite_time_partitions = true,
    retention = '90 days',
    retention_keep_table=false
  where parent_table = 'perfstat.pg_stat_activity_sample';

-- Create the function perfstat.error_generator
create or replace function perfstat.error_generator(msg varchar) returns boolean
as $$ begin raise '%',msg; end; $$ language plpgsql; 

-- Grant permission to postgresfdw
\qecho NOTE: Please ignore error from the following commands if the user postgresfdw has not been created yet
grant insert, select, update, delete on all tables in schema perfstat to postgresfdw;

\qecho NOTE: If you rerun this script, you need to rerun the script create_postgresi_user.sql also.    
