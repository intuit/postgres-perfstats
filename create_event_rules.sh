#!/bin/bash
# Usage: ./create_event_rules.sh <profile> <region> <endpoint> <dbname>
#        where <profile> is AWS account profile
#              <region> is AWS region
#              <endpoint> is Cluster endpoint
#              <dbname> is RDS db name
# Example
# ./create_event_rules.sh sbg-qbo-ppd us-west-2 pqbopc04p-instance-1.cozwkqglitfx.us-west-2.rds.amazonaws.com pqbopc04p

if [ $# -eq 4 ]; then
  profile=$1
  region=$2
  endpoint=$3
  dbname=$4
else
  echo "$0 <profile> <region> <endpoint>  <dbname>"
  echo "where <profile> is AWS account profile"
  echo "      <region> is AWS region"
  echo "      <endpoint> is Cluster endpoint"
  echo "      <dbname> is RDS db name"
  exit 1
fi


account=`aws --profile $profile sts get-caller-identity |grep Account |cut -d'"' -f4`

# Create a CloudWatch even rule to execute the Lambda function create_perfstat_snap every 15 minutes
aws --profile $profile --region $region events put-rule --name "create_perfstat_snap_${dbname}" --description "Create perfstat snap in Aurora Postgres db" --schedule-expression "cron(*/15 * ? * * *)"

aws --profile $profile --region $region events put-targets --rule "create_perfstat_snap_${dbname}" --targets "Id"="1","Arn"="arn:aws:lambda:${region}:${account}:function:create_perfstat_snap","Input"="\"{\\\"db_host\\\": \\\"${endpoint}\\\", \\\"db_name\\\": \\\"${dbname}\\\", \\\"db_username\\\": \\\"postgresi\\\"}\""

aws --profile $profile --region $region lambda add-permission --function-name create_perfstat_snap \
--statement-id create_perfstat_snap_${dbname} --action "lambda:InvokeFunction" \
--principal events.amazonaws.com --source-arn arn:aws:events:${region}:${account}:rule/create_perfstat_snap_${dbname}


# Create a CloudWatch even rule to execute the Lambda function create_perfstat_sample every minute
aws --profile $profile --region $region events put-rule --name "create_perfstat_sample_${dbname}" --description "Create perfstat sample in Aurora Postgres db" --schedule-expression "cron(* * ? * * *)"

aws --profile $profile --region $region events put-targets --rule "create_perfstat_sample_${dbname}" --targets "Id"="1","Arn"="arn:aws:lambda:${region}:${account}:function:create_perfstat_sample","Input"="\"{\\\"db_host\\\": \\\"${endpoint}\\\", \\\"db_name\\\": \\\"${dbname}\\\", \\\"db_username\\\": \\\"postgresi\\\"}\""

aws --profile $profile --region $region lambda add-permission --function-name create_perfstat_sample \
--statement-id create_perfstat_sample_${dbname} --action "lambda:InvokeFunction" \
--principal events.amazonaws.com --source-arn arn:aws:events:${region}:${account}:rule/create_perfstat_sample_${dbname}

