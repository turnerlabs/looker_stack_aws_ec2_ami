#!/bin/bash -xe

# this is the user-data script that runs on looker node instances(in a private subnet) when they first start up.
# it has a few if statements to generate database the looker user and config files if it's a brand new configuration otherwise theres not much going on here

echo "############# Pull looker user rds password down to instance from secrets manager #############"

secret=`aws secretsmanager get-secret-value --region <your aws region> --secret-id <your secret arn>`
token=$(echo $secret | jq -r .SecretString)

echo "RDS_KEY=$token" >> /etc/environment
echo "RDS_KEY=$token" >> /etc/profile.d/looker.sh

export RDS_KEY=$token

echo "############# Set initial environment variables for cron and systemd #############"

if [ "`aws s3 ls s3://lookercas-looker/sm_update.sh`" != "" ]; then
    # this contains the script to check for rds looker user password changes.  Allows for seemless rotation of passwords.
    echo "############# sm_update.sh found and copied from s3 #############"
    aws s3 cp s3://lookercas-looker/sm_update.sh /home/looker/looker/sm_update.sh --quiet
fi

if [ "`aws s3 ls s3://lookercas-looker/looker-db.yml`" != "" ]; then
    # this contains the yaml needed by looker to start up.
    echo "############# looker-db.yml found and copied from s3 #############"
    aws s3 cp s3://lookercas-looker/looker-db.yml /home/looker/looker/looker-db.yml --quiet
fi

echo "############# Copy important files from s3 locally #############"

if [ ! -e "/home/looker/looker/looker-db.yml" ]; then
    # On the initial run of looker create the looker user in the database
    mysql --host=<your rds database> --user=<your rds admin user> --password=<your rds admin password> -e "CREATE DATABASE IF NOT EXISTS <your looker database>;"
    mysql --host=<your rds database> --user=<your rds admin user> --password=<your rds admin password> -e "CREATE USER '<your looker user>'@'%' IDENTIFIED BY '<your looker users password>';"
    mysql --host=<your rds database> --user=<your rds admin user> --password=<your rds admin password> -e "GRANT ALL PRIVILEGES ON <your looker database>.* TO '<your looker user>'@'%';"
    mysql --host=<your rds database> --user=<your rds admin user> --password=<your rds admin password> -e "FLUSH PRIVILEGES;"

    echo "############# Completed database setup #############"

# Create the database credentials file
cat <<EOT | tee -a /home/looker/looker/looker-db.yml
host: <your rds database>
username: <your looker user>
password: <your looker users password>
database: <your looker database>
dialect: mysql
port: 3306
ssl: true
EOT

    chown -R looker:looker /home/looker/looker
    chmod 600 /home/looker/looker/looker-db.yml

    aws s3 cp /home/looker/looker/looker-db.yml <your looker s3 configuration bucket>/looker-db.yml --quiet

    echo "############# Generated looker-db.yml file #############"
fi

if [ ! -e "/home/looker/looker/sm_update.sh" ]; then
    echo "#!/bin/bash" >> /home/looker/looker/sm_update.sh
    echo $'' >> /home/looker/looker/sm_update.sh
    echo "secret=\`aws secretsmanager get-secret-value --region <your aws region> --secret-id <your secret arn>\`" >> /home/looker/looker/sm_update.sh
    echo $'' >> /home/looker/looker/sm_update.sh
    echo "token=\$(echo \$secret | jq -r .SecretString)" >> /home/looker/looker/sm_update.sh
    echo $'' >> /home/looker/looker/sm_update.sh

    echo "sudo sed -i -e \"/RDS_KEY/d\" /etc/environment" >> /home/looker/looker/sm_update.sh
    echo "sudo sed -i -e \"/RDS_KEY/d\" /etc/profile.d/looker.sh" >> /home/looker/looker/sm_update.sh

    echo "sudo sed -i -e \"$ a RDS_KEY=\$token\" /etc/environment" >> /home/looker/looker/sm_update.sh
    echo "sudo sed -i -e \"$ a RDS_KEY=\$token\" /etc/profile.d/looker.sh" >> /home/looker/looker/sm_update.sh

    chown -R looker:looker /home/looker/looker
    chmod 700 /home/looker/looker/sm_update.sh

    aws s3 cp /home/looker/looker/sm_update.sh <your looker s3 configuration bucket>/sm_update.sh --quiet

    echo "############# Generate sm_update.sh #############"
fi

# Determine the IP address of this instance so that it can be registered in the cluster
export IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
# Build the Looker arguments string that the looker jar will use on startup.  All the parameters would have been passed into terraform on the initial creation of the environment.
echo "LOOKERARGS=\"--clustered --no-ssl --prefer-ipv4 -H $IP -p 9999 -n 1551 -q "61616" -d /home/looker/looker/looker-db.yml --shared-storage-dir <your efs mount point> --scheduler-threads=20 --unlimited-scheduler-threads=15 --scheduler-query-limit=30 --per-user-query-limit=40 --scheduler-query-timeout=3600 --log-to-file=true\"" | sudo tee -a /home/looker/looker/lookerstart.cfg

chown -R looker:looker /home/looker/looker/
chmod 700 /home/looker/looker/sm_update.sh
chmod 600 /home/looker/looker/looker-db.yml

echo "############# Apply owndership and execution priviliges #############"

# do all the things needed to mount the EFS volume 
mkdir -p <your efs mount point>
echo "<your efs server>:/ <your efs mount point>" | sudo tee -a /etc/fstab
mount -a
chown looker:looker <your efs mount point>
cat /proc/mounts | grep looker

echo "############# Mount EFS #############"

systemctl enable datadog-agent.service
systemctl enable looker.service
systemctl daemon-reload

echo "############# Enabled looker and datadog systemd #############"

systemctl start datadog-agent.service
systemctl start looker.service

echo "############# Started up looker service #############"
