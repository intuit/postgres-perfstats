from postgres_utils import Messages
from postgres_utils import ScriptReader
from postgres_utils import PostgresDataManager
from datetime import datetime, timedelta
import json
import boto3

# Create CloudWatch client
cloudwatch = boto3.client('cloudwatch')

filename = "/tmp/create_host_stat.sql"
filename2 = "/tmp/create_perfstat_snap_for_ro_new.sql"

def create_host_stat_sql(instance_name, filename):

    response = cloudwatch.get_metric_statistics(
        Namespace='AWS/RDS',
        Dimensions=[
            {
                'Name': 'DBInstanceIdentifier',
                'Value': instance_name 
            }
        ],
        MetricName='CPUUtilization',
        StartTime=datetime.now() - timedelta(minutes=15),
        EndTime=datetime.now(),
        Period=900,
        Statistics=[
            'Average',
            'Maximum',
            'Minimum',
            'Sum'
        ]
    )

    metric = response['Label']
    maximum = response['Datapoints'][0]['Maximum']
    minimum = response['Datapoints'][0]['Minimum']
    sum = response['Datapoints'][0]['Sum']
    average = response['Datapoints'][0]['Average']
    sql_statement = "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Maximum', " + str(maximum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Minimum', " + str(minimum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Sum', " + str(sum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Average', " + str(average) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" 

    response = cloudwatch.get_metric_statistics(
        Namespace='AWS/RDS',
        Dimensions=[
            {
                'Name': 'DBInstanceIdentifier',
                'Value': instance_name
            }
        ],
        MetricName='ReadIOPS',
        StartTime=datetime.now() - timedelta(minutes=15),
        EndTime=datetime.now(),
        Period=900,
        Statistics=[
            'Average',
            'Maximum',
            'Minimum',
            'Sum'
        ]
    )

    metric = response['Label']
    maximum = response['Datapoints'][0]['Maximum']
    minimum = response['Datapoints'][0]['Minimum']
    sum = response['Datapoints'][0]['Sum']
    average = response['Datapoints'][0]['Average']
    sql_statement = sql_statement + '\n' \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Maximum', " + str(maximum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Minimum', " + str(minimum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Sum', " + str(sum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Average', " + str(average) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n"


    response = cloudwatch.get_metric_statistics(
        Namespace='AWS/RDS',
        Dimensions=[
            {
                'Name': 'DBInstanceIdentifier',
                'Value': instance_name
            }
        ],
        MetricName='WriteIOPS',
        StartTime=datetime.now() - timedelta(minutes=15),
        EndTime=datetime.now(),
        Period=900,
        Statistics=[
            'Average',
            'Maximum',
            'Minimum',
            'Sum'
        ]
    )

    metric = response['Label']
    maximum = response['Datapoints'][0]['Maximum']
    minimum = response['Datapoints'][0]['Minimum']
    sum = response['Datapoints'][0]['Sum']
    average = response['Datapoints'][0]['Average']
    sql_statement = sql_statement + '\n' \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Maximum', " + str(maximum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Minimum', " + str(minimum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Sum', " + str(sum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Average', " + str(average) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n"

    response = cloudwatch.get_metric_statistics(
        Namespace='AWS/RDS',
        Dimensions=[
            {   
                'Name': 'DBInstanceIdentifier',
                'Value': instance_name
            }
        ],
        MetricName='ReadThroughput',
        StartTime=datetime.now() - timedelta(minutes=15),
        EndTime=datetime.now(),
        Period=900,
        Statistics=[
            'Average',
            'Maximum',
            'Minimum',
            'Sum'
        ]
    )

    metric = response['Label']
    maximum = response['Datapoints'][0]['Maximum']
    minimum = response['Datapoints'][0]['Minimum']
    sum = response['Datapoints'][0]['Sum']
    average = response['Datapoints'][0]['Average']
    sql_statement = sql_statement + '\n' \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Maximum', " + str(maximum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Minimum', " + str(minimum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Sum', " + str(sum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Average', " + str(average) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n"

    response = cloudwatch.get_metric_statistics(
        Namespace='AWS/RDS',
        Dimensions=[
            {   
                'Name': 'DBInstanceIdentifier',
                'Value': instance_name
            }
        ],
        MetricName='WriteThroughput',
        StartTime=datetime.now() - timedelta(minutes=15),
        EndTime=datetime.now(),
        Period=900,
        Statistics=[
            'Average',
            'Maximum',
            'Minimum',
            'Sum'
        ]
    )

    metric = response['Label']
    maximum = response['Datapoints'][0]['Maximum']
    minimum = response['Datapoints'][0]['Minimum']
    sum = response['Datapoints'][0]['Sum']
    average = response['Datapoints'][0]['Average']
    sql_statement = sql_statement + '\n' \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Maximum', " + str(maximum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Minimum', " + str(minimum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Sum', " + str(sum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Average', " + str(average) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n"

    response = cloudwatch.get_metric_statistics(
        Namespace='AWS/RDS',
        Dimensions=[
            {
                'Name': 'DBInstanceIdentifier',
                'Value': instance_name
            }
        ],
        MetricName='ReadLatency',
        StartTime=datetime.now() - timedelta(minutes=15),
        EndTime=datetime.now(),
        Period=900,
        Statistics=[
            'Average',
            'Maximum',
            'Minimum',
            'Sum'
        ]
    )

    metric = response['Label']
    maximum = response['Datapoints'][0]['Maximum']
    minimum = response['Datapoints'][0]['Minimum']
    sum = response['Datapoints'][0]['Sum']
    average = response['Datapoints'][0]['Average']
    sql_statement = sql_statement + '\n' \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Maximum', " + str(maximum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Minimum', " + str(minimum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Sum', " + str(sum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Average', " + str(average) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n"

    response = cloudwatch.get_metric_statistics(
        Namespace='AWS/RDS',
        Dimensions=[
            {
                'Name': 'DBInstanceIdentifier',
                'Value': instance_name
            }
        ],
        MetricName='WriteLatency',
        StartTime=datetime.now() - timedelta(minutes=15),
        EndTime=datetime.now(),
        Period=900,
        Statistics=[
            'Average',
            'Maximum',
            'Minimum',
            'Sum'
        ]
    )

    metric = response['Label']
    maximum = response['Datapoints'][0]['Maximum']
    minimum = response['Datapoints'][0]['Minimum']
    sum = response['Datapoints'][0]['Sum']
    average = response['Datapoints'][0]['Average']
    sql_statement = sql_statement + '\n' \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Maximum', " + str(maximum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Minimum', " + str(minimum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Sum', " + str(sum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Average', " + str(average) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n"

    response = cloudwatch.get_metric_statistics(
        Namespace='AWS/RDS',
        Dimensions=[
            {
                'Name': 'DBInstanceIdentifier',
                'Value': instance_name
            }
        ],
        MetricName='FreeableMemory',
        StartTime=datetime.now() - timedelta(minutes=15),
        EndTime=datetime.now(),
        Period=900,
        Statistics=[
            'Average',
            'Maximum',
            'Minimum',
            'Sum'
        ]
    )

    metric = response['Label']
    maximum = response['Datapoints'][0]['Maximum']
    minimum = response['Datapoints'][0]['Minimum']
    sum = response['Datapoints'][0]['Sum']
    average = response['Datapoints'][0]['Average']
    sql_statement = sql_statement + '\n' \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Maximum', " + str(maximum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Minimum', " + str(minimum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Sum', " + str(sum) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n" + \
                    "insert into perfstat.host_stat_hist select a.*, '" + instance_name + "', '" + metric + "', 'Average', " + str(average) + " from (select * from perfstat.snap order by snap_id desc limit 1) a;\n"

    with open(filename, 'w+') as file:
        file.write(sql_statement)
        file.close()


def lambda_handler(event, context):   
    
    DB_CONNECTION={}
    DB_CONNECTION['db_host']=event['db_host']
    DB_CONNECTION['db_name']=event['db_name']
    DB_CONNECTION['db_username']=event['db_username']
    print(DB_CONNECTION)

    script = ScriptReader.get_script("create_perfstat_snap.sql")
    response = PostgresDataManager.run_update(script, DB_CONNECTION)
    response_message = response[0]
    response_result = response[1]
    print(f'response_message: {response_message}')
    print(f'response_result: {response_result}')

    sql_get_wr_instance = "select server_id" + '\n' \
                          "  from aurora_replica_status()" + '\n' \
                          "  where session_id = 'MASTER_SESSION_ID';"
    wr_instance_names = PostgresDataManager.run_query(sql_get_wr_instance, DB_CONNECTION)
    wr_instance_name = wr_instance_names[0][0]
    print(f'wr_instance_name: {wr_instance_name}')
    create_host_stat_sql(wr_instance_name, filename)
    script = ScriptReader.get_script(filename)
    response = PostgresDataManager.run_update(script, DB_CONNECTION)
    response_message = response[0]
    response_result = response[1]
    print(f'response_message: {response_message}')
    print(f'response_result: {response_result}')

    sql_get_ro_instance = "select server_id" + '\n' \
                          "  from aurora_replica_status()" + '\n' \
                          "  where exists (select 'x' from information_schema.foreign_tables where foreign_server_name = replace(server_id, '-', '_') and foreign_table_schema = 'perfstat')" + '\n' \
                          "    and session_id != 'MASTER_SESSION_ID';"
    
    ro_instances = PostgresDataManager.run_query(sql_get_ro_instance, DB_CONNECTION)
    for inst in ro_instances:
        reader_instance_name = inst[0]
        reader_instance_name_us = reader_instance_name.replace('-', '_')
        print(f'collectinng stats for reader instance: {reader_instance_name}')
        org_script = open("create_perfstat_snap_for_ro.sql", "rt")
        new_script = open(filename2, "wt")
        for line in org_script:
            #read replace the strings :reader_instance_name_us and :reader_instance_name and then write to output file
            new_script.write(line.replace(":reader_instance_name_us", reader_instance_name_us).replace(":reader_instance_name", reader_instance_name))
        org_script.close()
        new_script.close()
        script = ScriptReader.get_script(filename2)
       
        #print(f'script: {script}')

        response = PostgresDataManager.run_update(script, DB_CONNECTION)
        response_message = response[0]
        response_result = response[1]
        print(f'response_message: {response_message}')
        print(f'response_result: {response_result}')

        create_host_stat_sql(reader_instance_name, filename)
        script = ScriptReader.get_script(filename)
        response = PostgresDataManager.run_update(script, DB_CONNECTION)
        response_message = response[0]
        response_result = response[1]
        print(f'response_message: {response_message}')
        print(f'response_result: {response_result}')

    return json.dumps(response, default=str)
