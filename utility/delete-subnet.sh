#! /bin/bash
# Delete subnet after dependent network interface goes down

SUBNET_ID=$1

#App name
APP=$1

STATE=$(aws ec2 describe-subnets --subnet-id $SUBNET_ID | grep State | sed -e 's/[ ]//g' )

if [ "$STATE" == '"State":"available",' ]
then
	. ../utility/execute-aws.sh "aws ec2 delete-subnet --subnet-id $SUBNET_ID"
else
	echo Subnet does not exist
fi
