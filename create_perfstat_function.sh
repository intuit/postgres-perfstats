#!/bin/bash
# Usage: ./create_perfstat_function.sh <profile> <region> <vpc name>
#        where <profile> is AWS account profile
#              <region> is AWS region
#              <vpc name> is AWS VPC name

if [ $# -eq 3 ]; then
  profile=$1
  region=$2
  vpc_name=$3
else
  echo "Usage: ./create_perfstat_function.sh <profile> <region>"
  echo "where <profile> is AWS account profile"
  echo "      <region> is AWS region"
  echo "      <vpc name> is AWS VPC name"
  exit 1
fi

aws --profile $profile --region $region events list-rules --name-prefix 'create_perfstat' |egrep "create_perfstat_snap_|create_perfstat_sample_" |grep Arn |cut -d'"' -f4 |sort > existed_event_rules.txt
./create_function_postgres.sh $profile $region $vpc_name create_perfstat_snap extra_file_list_snap.txt
./create_function_postgres.sh $profile $region $vpc_name create_perfstat_sample extra_file_list_sample.txt

cat existed_event_rules.txt |while read event_rule
do
  echo "event_rule=$event_rule"
  statement_id=`echo $event_rule |cut -d'/' -f2`
  function_name=`echo $event_rule |cut -d'/' -f2 |cut -d'_' -f1-3`
  echo "statement_id=$statement_id"
  echo "function_name=$function_name"
  aws --profile $profile --region $region lambda add-permission --function-name $function_name \
  --statement-id $statement_id --action "lambda:InvokeFunction" \
  --principal events.amazonaws.com --source-arn $event_rule
done

rm -f existed_event_rules.txt
