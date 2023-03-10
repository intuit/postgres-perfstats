#!/bin/bash
# Usage: ./create_postgres_lambda_role.sh <profile> <region>
#        where <profile> is AWS account profile
#              <region> is AWS region

if [ $# -eq 2 ]; then
  profile=$1
  region=$2
else
  echo "Usage: ./create_postgres_lambda_role.sh <profile> <region>"
  echo "where <profile> is AWS account profile"
  echo "      <region> is AWS region"
  exit 1
fi

account=`aws --profile $profile --region $region sts get-caller-identity |grep Account |cut -d'"' -f4`

aws --profile $profile --region $region iam create-role --role-name postgres-lambda-role \
  --description "Role to grant access to postgres automation lambda" \
  --assume-role-policy-document file://postgres_lambda_assume_role.json 

aws --profile $profile --region $region iam create-policy --policy-name postgres-iam-authentication \
  --description "Policy to grant access to postgres automation lambda" \
  --policy-document file://postgres_iam_authentication.json 

aws --profile $profile --region $region iam attach-role-policy --role-name postgres-lambda-role --policy-arn arn:aws:iam::${account}:policy/postgres-iam-authentication
aws --profile $profile --region $region iam attach-role-policy --role-name postgres-lambda-role --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess
aws --profile $profile --region $region iam attach-role-policy --role-name postgres-lambda-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws --profile $profile --region $region iam attach-role-policy --role-name postgres-lambda-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole
