create role postgresi login;
grant rds_iam to postgresi;
grant usage on schema perfstat to postgresi;
grant create on schema perfstat to postgresi;
grant all privileges on all tables in schema perfstat to postgresi;
grant usage on schema apg_plan_mgmt to postgresi;
grant select on all tables in schema apg_plan_mgmt to postgresi;
grant usage on schema information_schema to postgresi;
grant select on all tables in schema information_schema to postgresi;
grant pg_read_all_stats to postgresi;
grant usage on schema partman to postgresi;
grant select, delete on partman.part_config to postgresi;
grant select, delete on partman.part_config_sub to postgresi;
\qecho NOTE: Please ignore if you see ERROR:  schema "pglogical" does not exist
grant usage on schema pglogical to postgresi;


\qecho Change the owner of all tables and partitions in perfstat to postgresi 
select 'alter table ' || b.nspname || '.' || a.relname || ' owner to postgresi;'
from pg_class a
join pg_namespace b on b.oid = a.relnamespace
join pg_tables c on b.nspname = c.schemaname and a.relname = c.tablename
where ((exists (select 'a' from pg_inherits d where d.inhparent = a.oid))
   or (not exists (select 'a' from pg_inherits d where d.inhrelid = a.oid)))
  and b.nspname = 'perfstat'
order by 1 \gexec

select 'alter table ' || nmsp_child.nspname || '.' || child.relname || ' owner to postgresi;'
from pg_inherits
join pg_class parent on pg_inherits.inhparent = parent.oid
join pg_class child on pg_inherits.inhrelid = child.oid
join pg_namespace nmsp_parent on nmsp_parent.oid = parent.relnamespace
join pg_namespace nmsp_child on nmsp_child.oid = child.relnamespace
join pg_tables tbl on nmsp_parent.nspname = tbl.schemaname and parent.relname = tbl.tablename 
where nmsp_child.nspname = 'perfstat'
order by 1 \gexec
