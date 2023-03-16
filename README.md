# Aurora Postgres Performance Statistics Repository

#### Table of contents

* [Overview](#overview)
* [Design Diagram](#design-diagram)
* [Deployment](#deployment)
    - [Create extensions](#Create-extensions)
    - [Create perfstat schema](#Create-perfstat-schema)
    - [Create db user](#Create-db-user)
    - [Create AMI role](#Create-AMI-role)
    - [Create Lambda functions](#Create-Lambda-functions)
    - [Grant db access to Lambda function](#Grant-db-access-to-Lambda-function)
    - [Create CloudWatch event rule](#Create-CloudWatch-event-rule)
    - [Enable statistics collection for readers](#Enable-statistics-collection-for-readers)
    - [(Optional) Change statistics collection frequency or retention](#Optional-Change-statistics-collection-frequency-or-retention)
    - [Recreate perfstat schema after major upgrade](#Recreate-perfstat-schema-after-major-upgrade)
* [Generate Aurora Postgres AWR, AWR SQL and AWR ASH reports](#Generate-Aurora-Postgres-AWR-AWR-SQL-AWR-ASH-reports)
    - [Generate AWR report](#Generate-AWR-report)
    - [Generate AWR SQL report](#Generate-AWR-SQL-report)
    - [Generate AWR ASH report](#Generate-AWR-ASH-report)
    - [Generate AWR report as batch](#Generate-AWR-report-as-batch)
* [View statistics](#View-statistics)


## Overview

Postgres has built-in performance statistics views like pg_stat_statements, pg_stat_activity and pg_stat_database. Aurora Postgres has additional views like apg_plan_mgmt.dba_plans. These views are important for database and SQL performance troubleshooting. However these views provide only cumulative statistics since last database restart or statistics reset and the statistics resides in memory only. To troubleshot any performance issue, we often need to review statistics for a particular window or compare statistics between different windows. For this purpose, this Git repo provides the scripts and instruction to build a performance statistics repository and constantly save statistics from these views. It also provides the scripts to generate performance reports similar to  Oracle AWR (Automatic Workload Repository) report, AWR SQL report and AWS ASH (Active Session History) report. 

### Design Diagram

The following diagram shows how to collect performance statistics and generate AWR reports.

![alt text](https://github.com/intuit/postgres-perfstats/blob/main/aurora_postgres_awr.png)
&nbsp;

## Deployment

### Create extensions 
Follow https://www.postgresql.org/docs/13/pgstatstatements.html and https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.html to create pg_stat_statements and apg_plan_mgmt extensions if they are not created yet.

### Create perfstat schema 
Run the SQL script create_perfstat_schema.sql to create the schema perfstat and tables in this schema.

```
<postgres> \i create_perfstat_schema.sql
```

### Create db user 
Verify or choose Password and IAM database authentication option for Aurora Postgres db through AWS Console or AWS CLI. No reboot is needed for changing authentication option. 

Create AMI authentication database user called postgresi by running the SQL script create_postgresi_user.sql.

```
<postgres> \i create_postgresi_user.sql 
```

### Create AMI role 
Create an AMI role to allow login to db using AMI authentication. This role will be used by the Lambda function created below

```
./create_postgres_lambda_role.sh <profile> <region>
#        where <profile> is AWS account profile
#              <region> is AWS region
```

### Create Lambda functions
Create the Lambda function create_perfstat_snap, which will save the statistics to perfstat's tables as one snapshot, and the Lambda function called create_perfstat_sample, which will save the statistics to one perfstat's table as one sample

```
./create_perfstat_function.sh <profile> <region> <vpc name>
#        where <profile> is AWS account profile
#              <region> is AWS region
#              <vpc name> is AWS VPC name

For example
./create_perfstat_function.sh myprofile us-west-2 myvpc
```

Note: The script create_function_postgres.sh can be used to create/deploy any Lambda function which need to access Aurora postgres db

### Grant db access to Lambda functions
Add Lambda function security group postgres_lambda_\<vpc id\> on port 5432 to Aurora Postgres db security group's inboond rule through AWS Console or CLI. The security group postgres_lambda_\<vpc id\> is created in previous step if not exists. 

### Create CloudWatch event rules
Create two CloudWatch even rules: one to execute the Lambda function create_perfstat_snap every 15 minutes and another one to execute the Lambda function create_perfstat_sample every minute

```
./create_event_rules.sh <profile> <region> <endpoint> <instancename> <dbname>
#        where <profile> is AWS account profile
#              <region> is AWS region
#              <endpoint> is Cluster endpoint
#              <dbname> is RDS db name

For example
./create_event_rules.sh myprofile us-west-2 mydb.cluster-xxxxxxxxxxx.us-west-2.rds.amazonaws.com mydb 
```

### Enable statistics collection for readers
As a prerequisite, make sure that your cluster's security group has inbound rules to allow connecting from their own subnets.
 
You may create one or several Aurora Postgres readers any time. To enable statistics collection for the readers, you just need to run the SQL script create_perfstat_foreign_table.sql, which will create user postgresfdw and several foreign tables for each reader. 

Note: Please make sure to enter reader instance endpoint, NOT cluster reader endpoint.
```
<postgres> \i create_perfstat_foreign_table.sql 

This script will prompt you:
Enter postgresfdw password
Enter reader instance endpoint
Enter reader db name

Here is a sample of inputs:

Enter postgresfdw password: <password>
Enter reader instance endpoint: mydb-instance-2.xxxxxxxxxxxx.us-west-2.rds.amazonaws.com
Enter reader db name: mydb 
```

### (Optional) Change statistics collection frequency or retention 
By default, it collects statistics every 15 minutes and keeps statistics for 90 days. You can change the frequency through CloudWatch event rule schedule or changing cron defination in the script create_event_rules.sh and (re)running the script. You can change the retention by running the script change_awr_retention.sql.

### Recreate perfstat schema after major upgrade 
If you perform a major Aurora ugprade, you need to recreate perfstat schema since likely some of Postgres performance statistics views will be changed. The following are the steps to recreate perfstat schema:

a) Rename the schema to keep old statistics
```
ALTER SCHEMA perfstat RENAME TO perfstat_old;
```
Note: You can still generate the AWR reports against old statistics using the modified scripts (changing perfstat to perfstat_old in the scripts)

b) Create perfstat schema (https://github.intuit.com/qbo/postgres_perfstats#Create-perfstat-schema)

c) Enable statistics collection for readers (https://github.intuit.com/qbo/postgres_perfstats#Enable-statistics-collection-for-readers)

  
## Generate Aurora Postgres AWR, AWR SQL and AWR ASH reports
### Generate AWR report 
Run the following SQL to genrate Aurora Postgres AWR report
```
For APG 13 or newer
awrrpt.sql

For APG 12 or older
awrrpt12.sql
```

awrrpt_writer_9185_9189.html and awrrpt_reader_9185_9189.html are sample AWR reports

### Generate AWR SQL report
Run the following SQL to genrate Aurora Postgres AWR SQL report
```
awrsqlrpt.sql
```
awrsqlrpt_writer_592_593.html and awrsqlrpt_writer_753_761.html is smaple AWR SQL reports

### Generate AWR ASH report
Run the following SQL to genrate Aurora Postgres AWR ASH report
```
ashrpt.sql
```
ashrpt_writer_0827_0800.html is a sample AWS ASH report

### Generate AWR report as batch 
Run the following command to genrate Aurora Postgres AWR reports for all instances
```
psql --username=<username> -h <cluster endpoint> -p <port> <db name> -f awrrpt_batch_by_time.sql -v begin_time='yyyy-mm-dd hh24:mi:ss' -v end_time='yyyy-mm-dd hh24:mi:ss'

Example
psql --username=postgres -h pqbo-prf-c12.cluster-cozwkqglitfx.us-west-2.rds.amazonaws.com -p 5432 pqboc12p -f awrrpt_batch_by_time.sql -v begin_time='2022-06-08 09:20:06' -v end_time='2022-06-08 10:30:10'

```

## View statistics
Run the following SQLs to view different statistics as you need. You can create and run your own SQLs to query the tables in the repository.

```
chk_db_hist.sql			chk_sql_hist.sql		chk_sql_hist_search_all.sql
chk_db_hist_all.sql		chk_sql_hist_all.sql		chk_table_hist.sql
chk_index_hist.sql		chk_sql_hist_by_queryid.sql	chk_table_hist_all.sql
chk_index_hist_all.sql		chk_sql_hist_search.sql
```
