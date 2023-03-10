\x off
\pset pager off
\pset footer off
select *
  from perfstat.snap
  order by 1;

\pset pager on
\x on

\pset footer off
\prompt 'Enter begin snap id: ' bsnap
\prompt 'Enter end snap id: ' esnap
\qecho 'Enter either queryid or sql hash'
\prompt '  queryid (or hit Return if not enter): ' queryid 
\prompt '  sql hash (or hit Return if not enter): ' sql_hash

select case :'sql_hash' when '' then '0' else :'sql_hash' end as sql_hash \gset
select case :'queryid' when '' then '0' else :'queryid' end as queryid \gset

\qecho sql_hash :sql_hash
\qecho queryid :queryid

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


\set report awrsqlrpt_:instance_type _:bsnap _:esnap.html

\o :report
\pset format aligned
\pset format html


\x off

\qecho <h1>WORKLOAD REPOSITORY SQL Report</h1>

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


--\pset format wrapped
--\pset columns 120

\qecho <h3>SQL Text</h3>
select distinct queryid, sql_hash "sql hash", sql_text "sql text"
  from perfstat.dba_plans_hist
  where snap_id between :bsnap and :esnap
    and (sql_hash = :sql_hash or queryid = :queryid)
    and instance_name = :'instance_name'
  order by 1, 2;

\qecho <h3>SQL Plan Statistics</h3>

select plan_hash "plan hash",
       enabled,                  
       status,                   
       round(estimated_startup_cost, 2) "estimated startup cost",   
       round(estimated_total_cost, 2) "estimated total cost",     
       -- stmt_name "stmt name",                
       -- param_types "param types",             
       -- param_list "param list",               
       plan_created "plan created",             
       last_verified "last verified",            
       last_validated "last validated",           
       last_used "last used",                
       created_by "created by",               
       -- compatibility_level "compatibility level",      
       environment_variables "environment variables",    
       has_side_effects "has side effects",         
       planning_time_ms "planning time ms",         
       execution_time_ms "execution time ms",        
       -- cardinality_error "cardinality error",        
       total_time_benefit_ms "total time benefit ms",    
       execution_time_benefit_ms "execution time benefit ms"
  from perfstat.dba_plans_hist a
  where snap_id = (select max(snap_id) 
                     from perfstat.dba_plans_hist x
                     where x.sql_hash = a.sql_hash
                       and x.plan_hash = a.plan_hash
                       and x.snap_id between :bsnap and :esnap)
    and (sql_hash = :sql_hash or queryid = :queryid)
    and instance_name = :'instance_name'
  order by 1, 2;

\qecho <h3>SQL Plan Outline</h3>

select distinct plan_hash "plan hash", replace(plan_outline, ' ', '&#160;') "plan outline"
  from perfstat.dba_plans_hist
  where snap_id between :bsnap and :esnap
    and (sql_hash = :sql_hash or queryid = :queryid)
    and instance_name = :'instance_name'
  order by 1, 2;

\pset format aligned
\o
\qecho Report :report has been generated

\pset footer on

\o format.sh
\qecho 'sed -i -e "s/&amp;/\\&/g"' :report
\qecho rm :report-e
\o
\! chmod +x format.sh
\! ./format.sh
\! rm format.sh
