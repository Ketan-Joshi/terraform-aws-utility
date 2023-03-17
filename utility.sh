#!/bin/bash

# Environment Variables
postgresql_endpoint=${postgresql_endpoint}
sonarqube_password=${sonarqube_password}
sonarqube_user=${sonarqube_user}
sonarqube_database=${sonarqube_database}

# update the package list
sudo apt update -y

# installing cloudwatch-agent
sudo wget https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb
sudo apt-get -f install
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

cat <<EOF >>/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent.json
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "metrics": {
        "append_dimensions": {
            "ImageId": "$${aws:ImageId}",
            "InstanceId": "$${aws:InstanceId}",
            "InstanceType": "$${aws:InstanceType}"
        },
        "metrics_collected": {
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        },
        "aggregation_dimensions" : [ 
            ["InstanceId", "InstanceType"]
        ]
    }
}
EOF

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent.json
sudo systemctl restart amazon-cloudwatch-agent.service

# install java
#sudo apt install java-1.8.0-openjdk-devel -y
sudo apt install unzip
sudo apt-get install openjdk-11-jdk -y

# download the SonarQube distribution
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.9.10.61524.zip

# unzip the downloaded package
unzip sonarqube-8.9.10.61524.zip

# move the extracted folder to /opt
sudo mv sonarqube-8.9.10.61524 /opt/sonarqube

# add sonar user
sudo useradd sonar

# set ownership of the SonarQube directory to the sonar user
sudo chown -R sonar:sonar /opt/sonarqube

# create a symlink for easier usage
sudo ln -s /opt/sonarqube/bin/linux-x86-64/sonar.sh /usr/bin/sonar

# create a system service for SonarQube
sudo bash -c 'cat <<EOF > /etc/systemd/system/sonar.service
[Unit]
Description=SonarQube service
After=network.target

[Service]
Type=forking
User=sonar
ExecStart=/usr/bin/sonar start
ExecStop=/usr/bin/sonar stop
User=sonar
Group=sonar
Restart=always

LimitNOFILE=65536
LimitNPROC=8192


[Install]
WantedBy=multi-user.target
EOF'

# configure SonarQube to use the RDS database
cat <<EOF >>/opt/sonarqube/conf/sonar.properties
# Configure the database connection
sonar.jdbc.username=$sonarqube_user
sonar.jdbc.password=$sonarqube_password
sonar.jdbc.url=jdbc:postgresql://$postgresql_endpoint:5432/$sonarqube_database?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true&useConfigs=maxPerformance

# Configure the web server port
sonar.web.port=9000
EOF

sudo sysctl -w vm.max_map_count=262144

# start the SonarQube service
sudo systemctl start sonar

# enable the SonarQube service to start at boot
sudo systemctl enable sonar

# check the status of the SonarQube service
sudo systemctl status sonar
