#!/bin/bash

# Start servers and install binaries

# exit on any failure
set -e

#App name
APP=$1
INSTANCE_TYPE=${2:-m4.large}

. ../conf/config.sh
if [ -f ../conf/aws-resource-ids.sh ]
then
	. ../conf/aws-resource-ids.sh
else
	echo "conf/aws-resource-ids.sh not found. Have you run install.sh or install-aws-resources.sh?"
	exit
fi
#from conf/config.sh
get_ami_by_region

 # prepare bootstrap file for user-data by prepending common configs
    cat ../conf/config.sh ../bootstrap/bootstrap.sh > bootstrap-temp.sh
    
#----------launch config---------------------------------
aws autoscaling create-launch-configuration --launch-configuration-name $APP --image-id $IMAGE --instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME --security-groups $SECURITY_GROUP --iam-instance-profile $PROFILE --user-data file://bootstrap-temp.sh

rm bootstrap-temp.sh

#----------auto scaling group----------------------------
aws autoscaling create-auto-scaling-group --auto-scaling-group-name $APP --launch-configuration-name $APP \
--load-balancer-names $STACK_NAME-prod --min-size 2 --max-size 10 --desired-capacity 2 --vpc-zone-identifier "$SUBNET_LIST"

aws autoscaling put-scaling-policy --auto-scaling-group-name $APP --policy-name $APP-scale-up --adjustment-type ChangeInCapacity --scaling-adjustment 1
aws autoscaling put-scaling-policy --auto-scaling-group-name $APP --policy-name $APP-scale-down --adjustment-type ChangeInCapacity --scaling-adjustment -1

POLICY_UP_JSON=$(aws autoscaling describe-policies --auto-scaling-group-name $APP --policy-names $APP-scale-up | grep PolicyARN)
POLICY_UP_ARN=$(echo $POLICY_UP_JSON | grep "PolicyARN" | sed -e 's/[,|"| ]//g' | sed -e 's/PolicyARN://g')

POLICY_DOWN_JSON=$(aws autoscaling describe-policies --auto-scaling-group-name $APP --policy-names $APP-scale-down | grep PolicyARN)
POLICY_DOWN_ARN=$(echo $POLICY_DOWN_JSON | grep "PolicyARN" | sed -e 's/[,|"| ]//g' | sed -e 's/PolicyARN://g')

aws cloudwatch put-metric-alarm --alarm-name $APP-high-cpu --alarm-description "Alarm if CPU too high" --alarm-actions $POLICY_UP_ARN \
--metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --evaluation-periods 3 --threshold 80 --comparison-operator GreaterThanThreshold 
aws cloudwatch put-metric-alarm --alarm-name $APP-low-cpu --alarm-description "Alarm if CPU too low" --alarm-actions $POLICY_DOWN_ARN \
--metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --evaluation-periods 3 --threshold 25 --comparison-operator LessThanThreshold 


