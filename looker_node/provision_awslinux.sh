#!/usr/bin/bash -x

set -e

sudo ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
echo "America/New_York" | sudo tee -a /etc/timezone
echo "------------------- updating time zone complete -------------------"

sudo yum update -y
sudo amazon-linux-extras install -y epel

sudo mv /home/ec2-user/datadog.repo /etc/yum.repos.d/datadog.repo
sudo yum makecache

sudo yum install -y \
openssl-devel \
libmcrypt-devel \
ca-certificates \
git \
curl \
tzdata \
urw-fonts \
glibc \
fontconfig \
freetype \
freetype-devel \
fontconfig-devel \
wget \
jq \
mysql-devel \
sudo \
chromium-browser \
libstdc++ \
netcat \
mysql \
amazon-efs-utils \
datadog-agent
echo "------------------- looker yum dependencies complete -------------------"

curl https://intoli.com/install-google-chrome.sh | bash
alias chromium='chromium'
sudo ln -s /usr/bin/google-chrome-stable /usr/bin/chromium
echo "------------------- chromium items complete -------------------"

sudo amazon-linux-extras enable corretto8
sudo yum install -y java-1.8.0-amazon-corretto-devel
echo "------------------- looker java dependency complete -------------------"

wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-x86_64.tar.bz2 -O /home/ec2-user/phantomjs-1.9.8-linux-x86_64.tar.bz2
sudo mkdir -p /opt/phantomjs
bzip2 -d /home/ec2-user/phantomjs-1.9.8-linux-x86_64.tar.bz2
sudo tar -xvf /home/ec2-user/phantomjs-1.9.8-linux-x86_64.tar --directory /opt/phantomjs/ --strip-components 1
sudo ln -s /opt/phantomjs/bin/phantomjs /usr/bin/phantomjs
rm /home/ec2-user/phantomjs-1.9.8-linux-x86_64.tar
echo "------------------- phantomjs dependency complete -------------------"

sudo cp /etc/sysctl.conf /etc/sysctl.conf.dist
echo "net.ipv4.tcp_keepalive_time=200" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_intvl=200" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_probes=5" | sudo tee -a /etc/sysctl.conf
echo "------------------- updated sysctl complete -------------------"

wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm -O /home/ec2-user/amazon-cloudwatch-agent.rpm
sudo rpm -i /home/ec2-user/amazon-cloudwatch-agent.rpm
echo "------------------- download aws logs -------------------"

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/home/ec2-user/awslogs.json -s
echo "------------------- install aws logs -------------------"

sudo systemctl status amazon-ssm-agent
echo "------------------- start of awslogs complete -------------------"

sudo systemctl enable amazon-ssm-agent
rm /home/ec2-user/amazon-cloudwatch-agent.rpm
echo "------------------- enable autostart of awslogs complete -------------------"

wget https://s3.amazonaws.com/turner-iso-artifacts/AlertLogicAgents/al-agent-LATEST-1.x86_64.rpm -O /home/ec2-user/al-agent_LATEST_amd64.rpm
echo "------------------- download threat manager -------------------"

sudo rpm -i /home/ec2-user/al-agent_LATEST_amd64.rpm
echo "------------------- install threat manager -------------------"

sudo systemctl enable al-agent
rm /home/ec2-user/al-agent_LATEST_amd64.rpm
echo "------------------- enable autostart of threat manager and remove deb-------------------"


sudo sh -c "sed 's/api_key:.*/api_key: ${DATADOG_API_KEY}/' /etc/datadog-agent/datadog.yaml.example > /etc/datadog-agent/datadog.yaml"
sudo cat /etc/datadog-agent/datadog.yaml
echo "------------------- setup datadog items-------------------"

sudo adduser looker
echo "------------------- add looker user and group complete -------------------"

sudo crontab /home/ec2-user/crontab.system
sudo mv /home/ec2-user/crontab.looker /home/looker/crontab.looker
sudo crontab -u looker /home/looker/crontab.looker
sudo chown looker:looker /home/looker/crontab.looker
echo "------------------- enable logs cleanup complete -------------------"

curl -o /home/ec2-user/looker.service https://raw.githubusercontent.com/looker/customer-scripts/master/startup_scripts/systemd/looker.service 
sudo mv /home/ec2-user/looker.service /etc/systemd/system/looker.service
sudo chmod 664 /etc/systemd/system/looker.service
echo "------------------- copy systemd components complete -------------------"

echo "limit      maxfiles 8192 8192"     | sudo tee -a /etc/security/limits.conf
echo "looker     soft     nofile     8192" | sudo tee -a /etc/security/limits.conf
echo "looker     hard     nofile     8192" | sudo tee -a /etc/security/limits.conf
echo "------------------- updated launchd complete -------------------"

echo '%looker ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers
echo "------------------- adding looker to sudoers complete -------------------"

sudo mkdir /home/looker/looker
sudo mkdir /home/looker/looker/deploy_keys
sudo mkdir /home/looker/.lookerjmx
echo "------------------- setup looker directories -------------------"

echo "monitorRole   readonly" | sudo tee -a /home/looker/.lookerjmx/jmxremote.access
echo "controlRole   readwrite \\" | sudo tee -a /home/looker/.lookerjmx/jmxremote.access
echo "              create javax.management.monitor.*,javax.management.timer.* \\" | sudo tee -a /home/looker/.lookerjmx/jmxremote.access
echo "              unregister" | sudo tee -a /home/looker/.lookerjmx/jmxremote.access

echo "monitorRole   some_password_here" | sudo tee -a /home/looker/.lookerjmx/jmxremote.password
echo "controlRole   some_password_here" | sudo tee -a /home/looker/.lookerjmx/jmxremote.password

echo "------------------- prtially setup jmx related items -------------------"

if [ "$LOOKER_VERSION" == "latest" ]; then
    echo "------------------- getting lastest looker jars -------------------"
    curl -X POST -H 'Content-Type: application/json' -d '{"lic": "'${LOOKER_LICENSE_KEY}'", "email": "'${LOOKER_LICENSE_EMAIL}'", "latest": "latest"}' https://apidownload.looker.com/download | jq '.url' | xargs curl -o /home/ec2-user/looker.jar
    curl -X POST -H 'Content-Type: application/json' -d '{"lic": "'${LOOKER_LICENSE_KEY}'", "email": "'${LOOKER_LICENSE_EMAIL}'", "latest": "latest"}' https://apidownload.looker.com/download | jq '.depUrl' | xargs curl -o /home/ec2-user/looker-dependencies.jar
else
    echo "------------------- getting version $LOOKER_VERSION of the looker jars -------------------"
    curl -X POST -H 'Content-Type: application/json' -d '{"lic": "'${LOOKER_LICENSE_KEY}'", "email": "'${LOOKER_LICENSE_EMAIL}'", "latest": "specific", "specific": "looker-'${LOOKER_VERSION}'-latest.jar"}' https://apidownload.looker.com/download | jq '.url' | xargs curl -o /home/ec2-user/looker.jar
    curl -X POST -H 'Content-Type: application/json' -d '{"lic": "'${LOOKER_LICENSE_KEY}'", "email": "'${LOOKER_LICENSE_EMAIL}'", "latest": "specific", "specific": "looker-'${LOOKER_VERSION}'-latest.jar"}' https://apidownload.looker.com/download | jq '.depUrl' | xargs curl -o /home/ec2-user/looker-dependencies.jar
fi
echo "------------------- download looker jars complete -------------------"

curl -o /home/ec2-user/looker https://raw.githubusercontent.com/looker/customer-scripts/master/startup_scripts/looker
sed -i -e "s/JAVAARGS=""/JAVAARGS="JMXARGS"/g" /home/ec2-user/looker
echo "------------------- download looker startup and modify to include JMX complete -------------------"

sudo mv /home/ec2-user/looker /home/looker/looker/looker
sudo mv /home/ec2-user/looker.jar /home/looker/looker/looker.jar
sudo mv /home/ec2-user/looker-dependencies.jar /home/looker/looker/looker-dependencies.jar
sudo chmod 0750 /home/looker/looker/looker
sudo chmod 0700 /home/looker/.lookerjmx
sudo chmod 0400 /home/looker/.lookerjmx/jmxremote.*
sudo chown -R looker:looker /home/looker/looker
sudo chown -R looker:looker /home/looker/.lookerjmx
echo "------------------- move files and set permissions complete -------------------"