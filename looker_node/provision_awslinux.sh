#!/usr/bin/bash -x

set -e

sudo ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
echo "America/New_York" | sudo tee -a /etc/timezone
echo "------------------- updating time zone complete -------------------"

sudo yum update -y
sudo amazon-linux-extras install -y epel

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
libstdc++
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

sudo adduser looker
echo "------------------- add looker user and group complete -------------------"

sudo crontab /home/ec2-user/crontab.system
sudo crontab -u looker /home/ec2-user/crontab.looker
echo "------------------- enable logs cleanup complete -------------------"

sudo cp /home/ec2-user/looker.sysconfig /etc/profile.d/looker.sh
sudo cp /home/ec2-user/looker.conf /usr/lib/tmpfiles.d

sudo cp /home/ec2-user/looker.service /etc/systemd/system/looker.service
sudo chmod 664 /etc/systemd/system/looker.service

rm /home/ec2-user/looker.sysconfig
rm /home/ec2-user/looker.conf
rm /home/ec2-user/looker.service
echo "------------------- copy systemd components complete -------------------"

sudo mkdir /run/looker
sudo chown looker:looker /run/looker
echo "------------------- modified pid directory complete -------------------"

echo "limit      maxfiles 8192 8192"     | sudo tee -a /etc/security/limits.conf
echo "looker     soft     nofile     8192" | sudo tee -a /etc/security/limits.conf
echo "looker     hard     nofile     8192" | sudo tee -a /etc/security/limits.conf
echo "------------------- updated launchd complete -------------------"

echo '%looker ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers
echo "------------------- adding looker to sudoers complete -------------------"

sudo mkdir /srv/data
sudo chown -R looker:looker /srv/data
echo "------------------- created looker directory -------------------"

sudo su - looker <<HERE
whoami
ls -al /home/looker
mkdir /home/looker/looker
curl -X POST -H 'Content-Type: application/json' -d '{"lic": "'${LOOKER_LICENSE_KEY}'", "email": "'${LOOKER_LICENSE_EMAIL}'", "latest": "specific", "specific": "looker-latest.jar"}' https://apidownload.looker.com/download | jq '.url' | xargs curl -o /home/looker/looker/looker.jar
curl -X POST -H 'Content-Type: application/json' -d '{"lic": "'${LOOKER_LICENSE_KEY}'", "email": "'${LOOKER_LICENSE_EMAIL}'", "latest": "specific", "specific": "looker-latest.jar"}' https://apidownload.looker.com/download | jq '.depUrl' | xargs curl -o /home/looker/looker/looker-dependencies.jar
HERE

echo "------------------- download looker jars complete -------------------"


java -version