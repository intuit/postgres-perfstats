from postgres_utils import Messages
from postgres_utils import ScriptReader
from postgres_utils import PostgresDataManager
import json

filename = "/tmp/create_perfstat_sample_for_ro_new.sql"

def lambda_handler(event, context):   
    
    DB_CONNECTION={}
    DB_CONNECTION['db_host']=event['db_host']
    DB_CONNECTION['db_name']=event['db_name']
    DB_CONNECTION['db_username']=event['db_username']

    print(DB_CONNECTION)

    script = ScriptReader.get_script("create_perfstat_sample.sql")
    response = PostgresDataManager.run_update(script, DB_CONNECTION)
    response_message = response[0]
    response_result = response[1]
    print(f'response_message: {response_message}')
    print(f'response_result: {response_result}')

    sql_get_ro_instance = "select server_id" + '\n' \
                          "  from aurora_replica_status()" + '\n' \
                          "  where exists (select 'x' from information_schema.foreign_tables where foreign_server_name = replace(server_id, '-', '_') and foreign_table_schema = 'perfstat')" + '\n' \
                          "    and session_id = 'MASTER_SESSION_ID';"

    ro_instance = PostgresDataManager.run_query(sql_get_ro_instance, DB_CONNECTION)
    for inst in ro_instance:
        reader_instance_name = inst[0]
        reader_instance_name_us = reader_instance_name.replace('-', '_')
        print(f'collectinng stats for reader instance: {reader_instance_name}')
        org_script = open("create_perfstat_sample_for_ro.sql", "rt")
        new_script = open(filename, "wt")
        for line in org_script:
            #read replace the strings :reader_instance_name_us and :reader_instance_name and then write to output file
            new_script.write(line.replace(":reader_instance_name_us", reader_instance_name_us).replace(":reader_instance_name", reader_instance_name))
        org_script.close()
        new_script.close()
        script = ScriptReader.get_script(filename)

        #print(f'script: {script}')

        new_script = open(filename, "rt")
        for line in new_script:
            print(f'line: {line}')
        new_script.close()

        response = PostgresDataManager.run_update(script, DB_CONNECTION)
        response_message = response[0]
        response_result = response[1]
        print(f'response_message: {response_message}')
        print(f'response_result: {response_result}')

    return json.dumps(response, default=str)
