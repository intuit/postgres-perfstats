import boto3
import pg8000
import os
import ssl

# Functions for reading scripts
class ScriptReader(object):

    @staticmethod
    def get_script(path):
        return open(path, 'r').read()

# Utils for messages
class Messages(object):

    @staticmethod
    def print_message(msg):
        print(f'---> {msg}')

# Postgres functions to send and retrieve data
class PostgresDataManager(object):

    @staticmethod
    def execute_update(con, cur, script):
        message = None

        try:
            cur.execute(script)
            con.commit()
            result = True
        except Exception as e:
            Messages.print_message(e)
            con.rollback()
            message = e
            result = False
        finally:
            con.close()

        return (result, message)

    @staticmethod
    def execute_query(con, cur, script):
        try:
            cur.execute(script)
            con.commit()
            result = cur.fetchall()
        except Exception as e:
            Messages.print_message(e)
            con.rollback()
            result = []
        finally:
            con.close()
        return result

    @staticmethod
    def get_conn_string(db_conn):
        return 'host="{}", user="{}", database="{}", port="5432",password="{}"'.format(
            db_conn['db_host'], db_conn['db_username'], db_conn['db_name'], db_conn['db_password'])

    @staticmethod
    def create_conn(conn_string):
        print(f'conn_string: {conn_string}')
        #return pg8000.connect(conn_string)
        return pg8000.connect(host=conn_string['db_host'],
                              user=conn_string['db_username'],
                              database=conn_string['db_name'],
                              password=conn_string['db_password'])
 
    @staticmethod
    def get_conn(db_connection):
        # Create a low-level client with the service name for rds
        client = boto3.client("rds")

        # Generates an auth token used to connect to a db with IAM credentials.
        password = client.generate_db_auth_token(
            DBHostname=db_connection['db_host'], Port=5432, DBUsername=db_connection['db_username']
        )

        # Establishes the connection with the server using the token generated as password
        context = ssl.create_default_context(purpose=ssl.Purpose.CLIENT_AUTH, cafile="rds-ca-2019-root.pem")

        return pg8000.connect(host=db_connection['db_host'],
                              user=db_connection['db_username'],
                              database=db_connection['db_name'],
                              password=password,
                              ssl_context=context)

    @staticmethod
    def run_update(script, db_connection):
        con = PostgresDataManager.get_conn(db_connection)
        return PostgresDataManager.execute_update(con, con.cursor(), script)

    @staticmethod
    def run_query(script, db_connection):
        con = PostgresDataManager.get_conn(db_connection)
        return PostgresDataManager.execute_query(con, con.cursor(), script)
