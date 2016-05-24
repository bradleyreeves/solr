#!/bin/bash

VPC_ID="<vpc-id>"
PROFILE="<profile-arn>"
STACK_NAME=solr
KEY_NAME=solr
ADMIN_IP_RANGE="<admin-range>"
VPC_IP_RANGE="<vpc-range>"
AWS_BUCKET="<aws-bucket>"
AWS_BUCKET_URL="<aws-bucket-url>"
REGION="<region>"
PRIVATE_ROUTE_TABLE="<route-table>"
ROUTE_HOSTED_ZONE=<route-hosted-zone>
ELB_HOSTED_ZONE=<elb-hosted-zone>
SERVER_INSTANCE_TYPE=<server-instance-type>

# map image / region
get_ami_by_region () {
	case "$REGION" in
	    "us-west-2")
			IMAGE=ami-d2c924b2
	    ;;
	    "us-west-1")
			IMAGE=ami-af4333cf
	    ;;
	    "eu-central-1")
			IMAGE=ami-9bf712f4
	    ;;
	    "eu-west-1")
			IMAGE=ami-7abd0209
	    ;;
	    "ap-southeast-1")
			IMAGE=ami-f068a193
	    ;;
	    "ap-southeast-2")
			IMAGE=ami-fedafc9d
	    ;;
	    "ap-northeast-1")
			IMAGE=ami-eec1c380
	    ;;
	    "sa-east-1")
			IMAGE=ami-26b93b4a
	    ;;
	    *)
	            echo $"No image found for specified REGION: $REGION"
	            exit 1
	esac
}

# map cidr / zone
get_cidr_by_zone () {
	case $ZONE in
	    a)
			SUBNET="<subnet-range>"
	    ;;
	    b)
			SUBNET="<subnet-range>"
	    ;;
	    c)
			SUBNET="<subnet-range>"
	    ;;
	    *)
	            echo $"Invalid ZONE: $ZONE"
	            exit 1
	esac
}
