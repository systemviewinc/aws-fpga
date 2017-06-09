#!/bin/bash
BUCKET_NAME=$1
LOGS_DIR=logs
DCP_DIR=dcp
LOCAL_CL_FILE=$2
USER_ID=$(aws iam get-user | python -c "import sys, json, re; j = json.load(sys.stdin)['User']['Arn']; print re.search('.*::(\d*)', j).group(1)")

enclose_in_box() {
	pre=; post=;
	if [ -z "$1" ]; then echo "Incorrect number of params passed"; return; fi
	if [ "$2" = inv ]; then pre=$l; post=$r; elif [ "$2" = bold ]; then pre="\033[1m"; post="\033[0m"; fi
	len=$((2 + ${#1}))
	line=$(printf "─%.0s" $(seq 1 ${len}))
	printf "┌$line┐\n│ ${pre}${1}${post} │\n└${line}┘\n"
}

if [ -z $1 ] || [ -z $2 ]; then enclose_in_box "Usage: $0 <bucket name (should be unique)> <CL tarball>"; exit; fi

CL_FILE=$(basename $LOCAL_CL_FILE)
PERMISSIONS="{\"Version\": \"2012-10-17\",\"Statement\": [{\"Sid\": \"Bucket level permissions\",\"Effect\": \"Allow\",\"Principal\": {\"AWS\": \"arn:aws:iam::365015490807:root\"},\"Action\": [\"s3:ListBucket\"],\"Resource\": \"arn:aws:s3:::${BUCKET_NAME}\"},{\"Sid\": \"Object read permissions\",\"Effect\": \"Allow\",\"Principal\": {\"AWS\": \"arn:aws:iam::365015490807:root\"},\"Action\": [\"s3:GetObject\"],\"Resource\": \"arn:aws:s3:::${BUCKET_NAME}/${DCP_DIR}/*\"},{\"Sid\": \"Logs folder write permissions\",\"Effect\": \"Allow\",\"Principal\": {\"AWS\": \"arn:aws:iam::365015490807:root\"},\"Action\": [\"s3:PutObject\"],\"Resource\": \"arn:aws:s3:::${BUCKET_NAME}/${LOGS_DIR}/*\"}, { \"Sid\": \"Bucket level permissions\", \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"arn:aws:iam::${USER_ID}:root\" }, \"Action\": [ \"s3:ListBucket\" ], \"Resource\": \"arn:aws:s3:::${BUCKET_NAME}\" }, { \"Sid\": \"Object write permissions\", \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"arn:aws:iam::${USER_ID}:root\" }, \"Action\": [ \"s3:PutObject\" ], \"Resource\": \"arn:aws:s3:::${BUCKET_NAME}/${DCP_DIR}/*\" }, { \"Sid\": \"Object read permissions\", \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"arn:aws:iam::${USER_ID}:root\" }, \"Action\": [ \"s3:GetObject\" ], \"Resource\": \"arn:aws:s3:::${BUCKET_NAME}/logs/*\" }]}"

POLICY_FILE="$(uuidgen)_policy.json"

enclose_in_box "Preparing Bucket \"${BUCKET_NAME}\" using CL FILE\"${CL_FILE}\""

enclose_in_box "Create bucket if it doesn't exist \"${BUCKET_NAME}\""
aws s3 mb s3://${BUCKET_NAME} --region us-east-1  # Create an S3 bucket (choose a unique bucket name)
if [ $? -ne 0 ];then exit $ret; fi

echo $PERMISSIONS > /tmp/${POLICY_FILE}
enclose_in_box "Applying policy \"${POLICY_FILE}\" to \"${BUCKET_NAME}\""
aws s3api put-bucket-policy --bucket ${BUCKET_NAME} --policy file:///tmp/${POLICY_FILE}
if [ $? -ne 0 ];then exit $ret; fi

enclose_in_box "Creating and copying CL File \"${LOCAL_CL_FILE}\" to \"${BUCKET_NAME}\""
aws s3 mb s3://${BUCKET_NAME}/${DCP_DIR}   # Create folder for your tarball files
if [ $? -ne 0 ];then exit $ret; fi
aws s3 cp ${LOCAL_CL_FILE} s3://${BUCKET_NAME}/${DCP_DIR}/
if [ $? -ne 0 ];then exit $ret; fi

enclose_in_box "Creating logs folder \"${BUCKET_NAME}/${LOGS_DIR}\""
aws s3 mb s3://${BUCKET_NAME}/${LOGS_DIR}  # Create a folder to keep your logs
if [ $? -ne 0 ];then exit $ret; fi
touch /tmp/LOGS_FILES_GO_HERE.txt                     # Create a temp file
aws s3 cp /tmp/LOGS_FILES_GO_HERE.txt s3://${BUCKET_NAME}/${LOGS_DIR}/  #Which creates the folder on S3
if [ $? -ne 0 ];then exit $ret; fi

# Verify that the bucket policy grants the required permissions

./check_s3_bucket_policy.py --dcp-bucket ${BUCKET_NAME} --dcp-key ${DCP_DIR}/${CL_FILE} --logs-bucket ${BUCKET_NAME} --logs-key ${LOGS_DIR}
