#! /bin/bash

yum -y update
yum -y install java
yum -y install tomcat
# create tomcat PID file
TOMCAT_PID=$(ps axf | grep tomcat | grep -v grep | awk '{print $1}')
echo $CATALINA_PID > /var/run/catalina.pid
curl $AWS_URL"get-pip.py" | python
# --ignore-installed  is required
pip install awscli --ignore-installed six
# download data and package files from S3
aws s3 cp $AWS_BUCKET"rvng-solr-1.0.1-1.noarch.rpm" rvng-solr.rpm
aws s3 cp $AWS_BUCKET"airports.txt" airports.txt
aws s3 cp $AWS_BUCKET"cities.txt" cities.txt
rpm --install --ignoreos rvng-solr.rpm
sed -i -e 's/<\/tomcat-users>/<role rolename="solr-admin"\/> \
<user name="admin" password="pass" roles="solr-admin" \/><\/tomcat-users>/' /usr/share/tomcat/conf/tomcat-users.xml
systemctl start tomcat
# wait for tomcat up
while [ "$CODE" != "200" ]
do
	CODE=$(curl --write-out %{http_code} --silent --output /dev/null localhost:8080/solr/)
	sleep 1
done
# load geonames data
for FILE in "cities.txt" "airports.txt"
do
	curl 'localhost:8080/solr/update/csv?commit=true&header=false&fieldnames=id,name,,altnames,latitude,longitude,featureclass,featurecode,countrycode,,altcountrycode,,,,,,,,&separator=%09&f.altnames.split=true&f.altnames.separator=,&encapsulator=\' -u admin:pass --data-binary @$FILE -H 'Content-type:text/plain; charset=utf-8'
done