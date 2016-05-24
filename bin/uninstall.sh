#! /bin/bash

. ../conf/config.sh

echo Delete AutoScaling Group may take several minutes while instances are shut down
nohup ../utility/kill-servers.sh solr &> ../log/kill-servers.out &
wait $!

	#----------load balancers--------------------------------
aws elb delete-load-balancer --load-balancer-name $STACK_NAME || true

	#----------subnets---------------------------------------
for ZONE in a b c
do
	SUBNET_JSON=$(aws ec2 describe-subnets --filters "Name=tag-value,Values=$STACK_NAME-private-$ZONE" | grep SubnetId)
	SUBNET_ID=$(echo $SUBNET_JSON | sed -e 's/[,|"]//g' | sed -e 's/SubnetId://g')
	echo Deleting subnets may take a minute while network interface is deleted
	nohup ./../utility/delete-subnet.sh $SUBNET_ID &> ../log/uninstall.out &
	PID=$!
	wait $PID
done

    #----------security groups-------------------------------
SECURITY_GROUP_JSON=$(aws ec2 describe-security-groups --filters "Name=description,Values=$STACK_NAME-private" | grep GroupId | sed -e 's/[ ]//g' | sort -u)
SECURITY_GROUP_ID=$(echo $SECURITY_GROUP_JSON | sed -e 's/[,|"]//g' | sed -e 's/GroupId://g')
aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID || true
