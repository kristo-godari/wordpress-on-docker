#!/bin/bash -l

#create backup directory
mkdir /workspace/backup

# download files
aws s3api get-object --bucket $AWS_BACKUP_BUCKET --key backups/database/database-backup.tar /workspace/backup/database-backup.tar
aws s3api get-object --bucket $AWS_BACKUP_BUCKET --key backups/webserver/webserver-backup.tar /workspace/backup/webserver-backup.tar

# unzip backup and replace old files
cd /var/www/vhosts/$DOMAIN_NAME/html/
touch test.txt
rm -r *
tar xvf /workspace/backup/webserver-backup.tar --strip 2

cd /var/lib/mysql
touch test.txt
rm -r *
tar xvf /workspace/backup/database-backup.tar --strip 2

# remove backup directory just to be sure that we start clean
rm -rf /workspace/backup