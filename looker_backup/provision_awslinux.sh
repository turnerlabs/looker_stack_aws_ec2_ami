#!/usr/bin/bash -x

set -e

sudo ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
echo "America/New_York" | sudo tee -a /etc/timezone
echo "------------------- updating time zone complete -------------------"

sudo yum update -y
sudo amazon-linux-extras install -y epel

sudo yum install -y \
amazon-efs-utils \
echo "------------------- backup yum dependencies complete -------------------"

wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm -O /home/ec2-user/amazon-cloudwatch-agent.rpm
sudo rpm -i /home/ec2-user/amazon-cloudwatch-agent.rpm
echo "------------------- download aws logs -------------------"

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/home/ec2-user/awslogs.json -s
echo "------------------- install aws logs -------------------"

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

sudo crontab /home/ec2-user/crontab.system
echo "------------------- create system crontab -------------------"