#!/bin/bash -l

#create backup directory
mkdir /workspace/backup

  : ${DOCKER_VOLUME_VERSION:=local}

# download files
aws s3api get-object --bucket $AWS_BACKUP_BUCKET --key $DOCKER_VOLUME_VERSION/backups/database/database-backup.tar /workspace/backup/database-backup.tar
aws s3api get-object --bucket $AWS_BACKUP_BUCKET --key $DOCKER_VOLUME_VERSION/backups/webserver/webserver-backup.tar /workspace/backup/webserver-backup.tar

# create a temp directory to unzip backup
mkdir /workspace/tmp && cd /workspace/tmp
tar xvf /workspace/backup/webserver-backup.tar --strip 2 

# cleanup old files and replace with new ones
cd /var/www/vhosts/
touch test.txt
rm -r *
cp -r /workspace/tmp/website-files/$DOMAIN_NAME /var/www/vhosts/

# fix permissions
chown -R nobody:nogroup "/var/www/vhosts/$DOMAIN_NAME/html/"

# copy webserver config 
cp -r /workspace/tmp/webserver-config/. /usr/local/lsws/conf
cp -r /workspace/tmp/webserver-certs/. /usr/local/lsws/cert
cp -r /workspace/tmp/sartup-files/. /home

# replace database files
cd /var/lib/mysql
touch test.txt
rm -r *
tar xvf /workspace/backup/database-backup.tar --strip 2

# remove backup and tmp directory just to be sure that we start clean
rm -rf /workspace/backup
rm -rf /workspace/tmp