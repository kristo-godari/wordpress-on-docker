#!/bin/bash -l

backup(){
  # create archives
  tar cvfz /workspace/backup/webserver-backup.tar /workspace/webserver/
  tar cvfz /workspace/backup/database-backup.tar /workspace/database/

  : ${DOCKER_VOLUME_VERSION:=local}

  # upload to s3
  aws s3api put-object --bucket $AWS_BACKUP_BUCKET --key $DOCKER_VOLUME_VERSION/backups/database/database-backup.tar --body /workspace/backup/database-backup.tar --region eu-central-1
  aws s3api put-object --bucket $AWS_BACKUP_BUCKET --key $DOCKER_VOLUME_VERSION/backups/webserver/webserver-backup.tar --body /workspace/backup/webserver-backup.tar --region eu-central-1
}

backup