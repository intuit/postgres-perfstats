#!/bin/bash
# Usage: ./create_function_postgres.sh <profile> <region> <vpc name> <function name> [<extra file list>]
#        where <profile> is AWS account profile
#              <region> is AWS region
#              <vpc name> is AWS VPC name
#              <function name> is name of Lambda function you want to create
#              <extra file list> is the file containing extra files needed

if [ $# -eq 4 -o $# -eq 5 ]; then
  profile=$1
  region=$2
  vpc_name=$3
  function_name=$4
  extra_file_list=$5
else
  echo "Usage: ./create_function_postgres.sh <profile> <region> <function name> [<extra file list>]"
  echo "where <profile> is AWS account profile"
  echo "      <region> is AWS region"
  echo "      <vpc name> is AWS VPC name"
  echo "      <function name> is name of Lambda function you want to create"
  echo "      <extra file list> is the file containing extra files needed"
  exit 1
fi

account=`aws --profile $profile --region $region sts get-caller-identity |grep Account |cut -d'"' -f4`

vpcid=`aws --profile $profile --region $region ec2 describe-vpcs --filters "Name=tag:Name,Values=${vpc_name}" --query 'Vpcs[0].VpcId' |cut -d'"' -f2`
echo "vpcid=${vpcid}"
if [ "$vpcid" == "null" ]; then
  echo "ERROR: The VPC ${vpc_name} does not exits"
  exit 1
fi

subnet1=`aws --profile $profile --region $region ec2 describe-subnets --filter "Name=vpc-id,Values=$vpcid" "Name=tag:Name,Values=PrivateSubnetAz1,PrivateSubnetAZ1" --query 'Subnets[0].SubnetId' |cut -d'"' -f2`
subnet2=`aws --profile $profile --region $region ec2 describe-subnets --filter "Name=vpc-id,Values=$vpcid" "Name=tag:Name,Values=PrivateSubnetAz2,PrivateSubnetAZ2" --query 'Subnets[0].SubnetId' |cut -d'"' -f2`
subnet3=`aws --profile $profile --region $region ec2 describe-subnets --filter "Name=vpc-id,Values=$vpcid" "Name=tag:Name,Values=PrivateSubnetAz3,PrivateSubnetAZ3" --query 'Subnets[0].SubnetId' |cut -d'"' -f2`

# Create security group postgres_lambda_${vpcid} if not exists
group_id=`aws --profile $profile --region $region ec2 describe-security-groups --filters "Name=group-name,Values=postgres_lambda_${vpcid}" --query 'SecurityGroups[*].{GroupId: GroupId}' |grep "GroupId" |cut -d'"' -f4`
echo "Security Group ID: $group_id"
if [ "$group_id" == "" ]; then
  aws --profile $profile --region $region ec2 create-security-group --group-name postgres_lambda_${vpcid} --description "postgres_lambda_${vpcid} security group" --vpc-id ${vpcid}
  group_id=`aws --profile $profile --region $region ec2 describe-security-groups --filters "Name=group-name,Values=postgres_lambda_${vpcid}" --query 'SecurityGroups[*].{GroupId: GroupId}' |grep "GroupId" |cut -d'"' -f4`
  echo "Security Group ID: $group_id"
  aws --profile $profile --region $region ec2 create-tags --resources $group_id --tags Key=Name,Value=postgres_lambda_${vpcid}
fi


aws --profile $profile --region $region lambda delete-function --function-name ${function_name}
rm -f ${function_name}.zip
if [ "$extra_file_list" != "" ]; then
  zip -r ${function_name}.zip ${function_name}.py postgres_utils.py ${function_name}.sql pg8000 scramp asn1crypto rds-ca-2019-root.pem `cat $extra_file_list`
else
  zip -r ${function_name}.zip ${function_name}.py postgres_utils.py ${function_name}.sql pg8000 scramp asn1crypto rds-ca-2019-root.pem
fi
description=`echo "${function_name}" |tr -s '_' ' '`
aws --profile $profile --region $region lambda create-function \
--function-name ${function_name} \
--description "$description" \
--zip-file fileb://${function_name}.zip \
--role arn:aws:iam::${account}:role/postgres-lambda-role \
--handler ${function_name}.lambda_handler \
--runtime python3.8 \
--vpc-config SubnetIds=${subnet1},${subnet2},${subnet3},SecurityGroupIds=${group_id} \
--timeout 900
