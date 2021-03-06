#!/bin/bash

# This is the script that EC2-user-data downloads and executes.
# Responsible for setting up all components for the container monitoring platform.
# - Anish Sujanani

yum -y update && yum -y upgrade

# install and run docker
amazon-linux-extras install docker -y
service docker start

# install kernel headers and Falco
rpm --import https://falco.org/repo/falcosecurity-3672BA8F.asc
curl -s -o /etc/yum.repos.d/falcosecurity.repo https://falco.org/repo/falcosecurity-rpm.repo;
yum -y install kernel-devel-$(uname -r);
yum -y install falco;

# pull scripts from Github 
mkdir /custom_falco_config;
cd /custom_falco_config;
wget https://raw.githubusercontent.com/anishsujanani/container-monitoring-platform-automation/master/falco_custom.yaml;
wget https://raw.githubusercontent.com/anishsujanani/container-monitoring-platform-automation/master/aggregate_alerts.py;

# install ES lib for python3.x
pip3 install elasticsearch;

# run elasticsearch container
docker run \
	-p 9200:9200 \
	-p 9300:9300 \
	--name elasticsearch \
	-e "discovery.type=single-node" \
	--rm \
	-d \
	docker.elastic.co/elasticsearch/elasticsearch:7.12.1;

echo "[!] Waiting for Elasticsearch to start, sleeping 20s"
sleep 20;

# run kibana container
docker run \
	-p 5601:5601 \
	--name kibana \
	--link elasticsearch:elasticsearch \
	--rm \
	-d \
	docker.elastic.co/kibana/kibana:7.12.1;
echo "[!] Waiting for Kibana to start, sleeping 30s"
sleep 30;

# run falco with paths to custom config files
falco -c ./falco_custom.yaml \
        -r /etc/falco/falco_rules.yaml \
        -r /etc/falco/falco_rules.local.yaml \
        -r /etc/falco/k8s_audit_rules.yaml &
echo "[!] Waiting for Falco to start, sleeping 5s"
sleep 5;

# manual creation of the index is no longer needed, this is done through the import-dashboard API
#curl -X POST \
#        -H 'kbn-xsrf: true' \
#        -H 'Content-Type: application/json' \
#	-d '{"index_pattern": {"title": "test*", "timeFieldName": "timestamp"}}' \
#        localhost:5601/api/index_patterns/index_pattern;

# pull kibana dashboard as JSON
wget https://raw.githubusercontent.com/anishsujanani/container-monitoring-platform-automation/master/dashboard_export.json;

# create kibana index and dashboard via API
curl -X POST \
	-H 'kbn-xsrf: true' \
	-H 'Content-Type: application/json' \
	-d @dashboard_export.json \
	localhost:5601/api/kibana/dashboards/import;

# Run the event generator for 5 minutes
docker run --rm falcosecurity/event-generator run syscall --loop & 
sleep 300; 
kill $!;
