#!/bin/bash

# Environment Variables
postgresql_endpoint=${postgresql_endpoint}
sonarqube_password=${sonarqube_password}
sonarqube_user=${sonarqube_user}
sonarqube_database=${sonarqube_database}

# update the package list
sudo apt update -y

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

sudo apt install nginx -y

sudo bash -c 'cat <<EOF > /etc/nginx/default.d/sonar.conf
server{
    listen 8080;
    server_name _;
    location / {
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://127.0.0.1:9000/;
    }
}
EOF'

sudo nginx -t
sudo systemctl start nginx
sudo systemctl enable nginx