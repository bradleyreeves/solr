#! /bin/bash

. ../conf/config.sh

# exit on any failure
set -e

trap \
	'if [ "$?" != "0" ]; \
then \
	echo "Script failed, rolling back."; \
	./uninstall.sh
fi' \
exit

	#----------security group------------------------------
SG_JSON=$(aws ec2 create-security-group --group-name $STACK_NAME --description $STACK_NAME-private --vpc-id $VPC_ID | grep GroupId)
SG_ID=$(echo $SG_JSON | sed -e 's/[,|"| ]//g' | sed -e 's/GroupId://g')
	# Saving security group and subnet parameters to conf/aws-resource-ids.sh
echo "SECURITY_GROUP=$SG_ID" > "../conf/aws-resource-ids.sh"
	# repeat for more inbound rules, replace "ingress" with "egress" for outbound rules
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80  --cidr 138.113.0.0/16
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22  --cidr 138.113.0.0/16
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 0-65535  --source-group $SG_ID
aws ec2 create-tags --resources $SG_ID --tags Key=Name,Value=$STACK_NAME

	#----------subnets---------------------------------------
for ZONE in a b c
do
	# defined in conf/config.sh
	get_cidr_by_zone
	# create the subnet
	SUBNET_JSON=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET --availability-zone $REGION$ZONE | grep SubnetId)
	# store the subnet id
	SUBNET_ID=$(echo $SUBNET_JSON | sed -e 's/[,|"| ]//g' | sed -e 's/SubnetId://g')
	# tag the subnet
	aws ec2 create-tags --resources $SUBNET_ID --tags Key=Name,Value="$STACK_NAME-private-$ZONE"
	# create a list of subnet
	SUBNET_LIST="$SUBNET_LIST $SUBNET_ID"

		#------------------route table-----------------------
	aws ec2 associate-route-table --subnet-id $SUBNET_ID --route-table-id rtb-ae020fcb
done
	# remove first space
SUBNET_LIST=`echo $SUBNET_LIST | sed 's/^ //'`
	# save the list of subnets for later
echo "SUBNET_LIST=${SUBNET_LIST// /,}" >> "../conf/aws-resource-ids.sh"

	#----------load balancers--------------------------------
LOAD_BALANCER_JSON=$(aws elb create-load-balancer --load-balancer-name $STACK_NAME-prod --security-groups $SG_ID --listeners \
Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=8080,SSLCertificateId=arn:aws:iam::490283132601:server-certificate/pegsservicescom \
--subnets $SUBNET_LIST --scheme internal | grep DNSName)
LOAD_BALANCER=$(echo $LOAD_BALANCER_JSON | sed -e 's/[,|"| ]//g' | sed -e 's/DNSName://g')
aws elb configure-health-check --load-balancer-name $STACK_NAME-prod --health-check "Target=TCP:8080,Interval=10,Timeout=5,UnhealthyThreshold=2,HealthyThreshold=2"

echo "See conf/aws-resource-ids.sh for subnet and security group IDs"

	#-----------servers--------------------------------------
. ../utility/boot-servers.sh solr $SERVER_INSTANCE_TYPE 2> ../log/server.out



echo Success
