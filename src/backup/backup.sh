#!/bin/bash -l

backup(){
  # create archives
  tar cvfz /workspace/backup/webserver-backup.tar /workspace/webserver/
  tar cvfz /workspace/backup/database-backup.tar /workspace/database/

  # upload to s3
  aws s3api put-object --bucket $AWS_BACKUP_BUCKET --key backups/database/database-backup.tar --body /workspace/backup/database-backup.tar
  aws s3api put-object --bucket $AWS_BACKUP_BUCKET --key backups/webserver/webserver-backup.tar --body /workspace/backup/webserver-backup.tar
}

if [ $DEPLOYMENT_ENV = "prod" ]; then
  backup
fi
