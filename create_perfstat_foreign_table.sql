\prompt 'Enter postgresfdw password: ' password
\prompt 'Enter reader instance endpoint: ' reader_instance_endpoint
\prompt 'Enter reader db name: ' db_name

-- Create user postgresfdw if not exits
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles  -- SELECT list can be empty for this
      WHERE  rolname = 'postgresfdw') THEN

      CREATE ROLE postgresfdw LOGIN;
   END IF;
END
$do$;

ALTER ROLE postgresfdw PASSWORD :'password';

grant insert, select, update, delete on all tables in schema perfstat to postgresfdw;
grant create on schema perfstat to postgresfdw;
grant usage on schema perfstat to postgresfdw;
grant usage on schema apg_plan_mgmt to postgresfdw;
grant select on all tables in schema apg_plan_mgmt to postgresfdw;
grant pg_read_all_stats to postgresfdw;

-- Create extension postgres_fdw if not exits
create extension if not exists postgres_fdw;

------------------------------------------
-- Create foreign table for reader instance
------------------------------------------

select substr(:'reader_instance_endpoint', 1, position('.' in :'reader_instance_endpoint') - 1) as reader_instance_name \gset
select replace(:'reader_instance_name', '-', '_') as reader_instance_name_us \gset

\echo reader_instance_name_us: :reader_instance_name_us

create server if not exists :reader_instance_name_us foreign data wrapper postgres_fdw options (host :'reader_instance_endpoint', dbname :'db_name');

\des

-- Create user mapping for postgresfdw
create user mapping if not exists for public server :reader_instance_name_us options (user 'postgresfdw', password :'password');

\deu

-- Create foreign tables
select
  'drop foreign table if exists perfstat.' || 'instance_start_time' || '_' || :'reader_instance_name_us' || ';' \gexec

select
  'create foreign table perfstat.instance_start_time_' || :'reader_instance_name_us' ||
  E'    (pg_postmaster_start_time timestamp with time zone) server ' || :'reader_instance_name_us' ||
  E'     options (schema_name ''perfstat'', table_name ''instance_start_time_view'')' || ';' \gexec


select
  'drop foreign table if exists perfstat.' || 'pg_stat_activity' || '_' || :'reader_instance_name_us' || ';' \gexec 

select
  'create foreign table if not exists perfstat.' || relname || '_' || :'reader_instance_name_us' || E'\n(\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    ) 
    , E',\n'
  ) || E'\n) server ' || :'reader_instance_name_us' || ' options (schema_name ''' || nspname || ''', table_name ''' || relname || ''');'
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


select
  'drop foreign table if exists perfstat.' || 'pg_stat_all_indexes' || '_' || :'reader_instance_name_us' || ';' \gexec 

select
  'create foreign table if not exists perfstat.' || relname || '_' || :'reader_instance_name_us' || E'\n(\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) server ' || :'reader_instance_name_us' || ' options (schema_name ''' || nspname || ''', table_name ''' || relname || ''');'
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


select
  'drop foreign table if exists perfstat.' || 'pg_stat_all_tables' || '_' || :'reader_instance_name_us' || ';' \gexec 

select
  'create foreign table if not exists perfstat.' || relname || '_' || :'reader_instance_name_us' || E'\n(\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) server ' || :'reader_instance_name_us' || ' options (schema_name ''' || nspname || ''', table_name ''' || relname || ''');'
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


select
  'drop foreign table if exists perfstat.' || 'pg_stat_database' || '_' || :'reader_instance_name_us' || ';' \gexec 

select
  'create foreign table if not exists perfstat.' || relname || '_' || :'reader_instance_name_us' || E'\n(\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) server ' || :'reader_instance_name_us' || ' options (schema_name ''' || nspname || ''', table_name ''' || relname || ''');'
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


select
  'drop foreign table if exists perfstat.' || 'pg_stat_statements' || '_' || :'reader_instance_name_us' || ';' \gexec 

select
  'create foreign table if not exists perfstat.' || relname || '_' || :'reader_instance_name_us' || E'\n(\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) server ' || :'reader_instance_name_us' || ' options (schema_name ''' || 'public' || ''', table_name ''' || relname || ''');'
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


select
  'drop foreign table if exists perfstat.' || 'dba_plans' || '_' || :'reader_instance_name_us' || ';' \gexec 

select
  'create foreign table if not exists perfstat.' || relname || '_' || :'reader_instance_name_us' || E'\n(\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) server ' || :'reader_instance_name_us' || ' options (schema_name ''' || nspname || ''', table_name ''' || relname || ''');'
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


------------------------------------------
-- Create foreign table for writer instance
------------------------------------------


-- Create server for writer instance 
select server_id as writer_instance_name 
  from aurora_replica_status()
  where session_id = 'MASTER_SESSION_ID' \gset

select replace(:'writer_instance_name', '-', '_') as writer_instance_name_us \gset
\echo writer_instance_name_us: :writer_instance_name_us

select replace(:'reader_instance_endpoint', :'reader_instance_name', :'writer_instance_name') as writer_instance_endpoint \gset
\echo writer_instance_endpoint: :writer_instance_endpoint

create server if not exists :writer_instance_name_us foreign data wrapper postgres_fdw options (host :'writer_instance_endpoint', dbname :'db_name');

\des

-- Create user mapping for postgresfdw
create user mapping for public server :writer_instance_name_us options (user 'postgresfdw', password :'password');

\deu

-- Create foreign tables

select
  'drop foreign table if exists perfstat.' || 'instance_start_time' || '_' || :'writer_instance_name_us' || ';' \gexec

select
  'create foreign table perfstat.instance_start_time_' || :'writer_instance_name_us' ||
  E'    (pg_postmaster_start_time timestamp with time zone) server ' || :'writer_instance_name_us' ||
  E'     options (schema_name ''perfstat'', table_name ''instance_start_time_view'')' || ';' \gexec


select
  'drop foreign table if exists perfstat.' || 'pg_stat_activity' || '_' || :'writer_instance_name_us' || ';' \gexec 

select
  'create foreign table if not exists perfstat.' || relname || '_' || :'writer_instance_name_us' || E'\n(\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    ) 
    , E',\n'
  ) || E'\n) server ' || :'writer_instance_name_us' || ' options (schema_name ''' || nspname || ''', table_name ''' || relname || ''');'
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


select
  'drop foreign table if exists perfstat.' || 'pg_stat_all_indexes' || '_' || :'writer_instance_name_us' || ';' \gexec 

select
  'create foreign table if not exists perfstat.' || relname || '_' || :'writer_instance_name_us' || E'\n(\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) server ' || :'writer_instance_name_us' || ' options (schema_name ''' || nspname || ''', table_name ''' || relname || ''');'
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


select
  'drop foreign table if exists perfstat.' || 'pg_stat_all_tables' || '_' || :'writer_instance_name_us' || ';' \gexec 

select
  'create foreign table if not exists perfstat.' || relname || '_' || :'writer_instance_name_us' || E'\n(\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) server ' || :'writer_instance_name_us' || ' options (schema_name ''' || nspname || ''', table_name ''' || relname || ''');'
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


select
  'drop foreign table if exists perfstat.' || 'pg_stat_database' || '_' || :'writer_instance_name_us' || ';' \gexec 

select
  'create foreign table if not exists perfstat.' || relname || '_' || :'writer_instance_name_us' || E'\n(\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) server ' || :'writer_instance_name_us' || ' options (schema_name ''' || nspname || ''', table_name ''' || relname || ''');'
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


select
  'drop foreign table if exists perfstat.' || 'pg_stat_statements' || '_' || :'writer_instance_name_us' || ';' \gexec 

select
  'create foreign table if not exists perfstat.' || relname || '_' || :'writer_instance_name_us' || E'\n(\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) server ' || :'writer_instance_name_us' || ' options (schema_name ''' || 'public' || ''', table_name ''' || relname || ''');'
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


select
  'drop foreign table if exists perfstat.' || 'dba_plans' || '_' || :'writer_instance_name_us' || ';' \gexec 

select
  'create foreign table if not exists perfstat.' || relname || '_' || :'writer_instance_name_us' || E'\n(\n' ||
  array_to_string(
    array_agg(
      '    ' || column_name || ' ' ||  type || ' '|| not_null
    )
    , E',\n'
  ) || E'\n) server ' || :'writer_instance_name_us' || ' options (schema_name ''' || nspname || ''', table_name ''' || relname || ''');'
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

-- List all foreign tables
\det perfstat.*

grant insert, select, update, delete on all tables in schema perfstat to postgresfdw;
grant insert, select, update, delete on all tables in schema perfstat to postgresi;

