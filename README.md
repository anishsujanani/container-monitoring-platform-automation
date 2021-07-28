# Container Security Platform Automation.

This repository contains the files needed to single-click deploy AWS infrastructure and set up Falco (a sys-call based container IDS) via Cloudformation templates and bash scripts.  


## For a detailed walkthrough 
Take a look at [this blog post][0].  


## A Brief Overview 
**Cloudformation Inputs**
- EC2-instace Type
- IP Address to whitelist for Kibana
- SSH key pair name

**Cloudformation Outputs**
- VPC, (public) subnet, non-elastic IP assignment, IGW, route tables.
- EBS volume, EC2 instance, appropriate security groups.
- EC2 user-data script that downloads and runs `ec2_setup.sh` from this repo.

**ec2_setup.sh**
- Installs all neccessary components.
- Runs containerized instances of Elasticsearch, Kibana and Falco event-generator.
- Runs Falco with a custom config and Python <-> ES integration.
- Configures indices and dashboards via the Kibana API by importing the file `dashboard_export.json`  



## Outputs
![kib-dash-1](https://raw.githubusercontent.com/anishsujanani/container-monitoring-platform-automation/master/kib_dashboard_updated.png)


[0]: https://www.anishsujanani.me/2021/07/28/auto-deploying-a-container-monitoring-platform.html