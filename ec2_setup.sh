#!/bin/bash

yum -y update && yum -y upgrade

amazon-linux-extras install docker -y
service docker start

rpm --import https://falco.org/repo/falcosecurity-3672BA8F.asc
curl -s -o /etc/yum.repos.d/falcosecurity.repo https://falco.org/repo/falcosecurity-rpm.repo;

yum -y install kernel-devel-$(uname -r);
yum -y install falco;

# pull config files and python scripts from github, store tham 
mkdir /custom_falco_config;
cd /custom_falco_config;
wget https://raw.githubusercontent.com/anishsujanani/container-monitoring-platform-automation/master/falco_custom.yaml;
wget https://raw.githubusercontent.com/anishsujanani/container-monitoring-platform-automation/master/aggregate_alerts.py;

pip3 install elasticsearch;

# run elasticsearch and kibana container
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

docker run \
	-p 5601:5601 \
	--name kibana \
	--link elasticsearch:elasticsearch \
	--rm \
	-d \
	docker.elastic.co/kibana/kibana:7.12.1;
echo "[!] Waiting for Kibana to start, sleeping 30s"
sleep 30;

falco -c ./falco_custom.yaml \
        -r /etc/falco/falco_rules.yaml \
        -r /etc/falco/falco_rules.local.yaml \
        -r /etc/falco/k8s_audit_rules.yaml &
echo "[!] Waiting for Falco to start, sleeping 5s"
sleep 5;

curl -X POST \
        -H 'kbn-xsrf: true' \
        -H 'Content-Type: application/json' \
	-d '{"index_pattern": {"title": "test*", "timeFieldName": "timestamp"}}' \
        localhost:5601/api/index_patterns/index_pattern;

wget https://raw.githubusercontent.com/anishsujanani/container-monitoring-platform-automation/master/dashboard_export.json;

curl -X POST \
	-H 'kbn-xsrf: true' \
	-H 'Content-Type: application/json' \
	-d @dashboard_export.json \
	localhost:5601/api/kibana/dashboards/import?exclude=index-pattern;


# Run the event generator for 5 minutes
docker run --rm falcosecurity/event-generator run syscall --loop & 
sleep 300; 
kill $!;
