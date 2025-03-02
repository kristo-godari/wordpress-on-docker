FROM ubuntu:latest

# update an install packages
RUN apt-get update --fix-missing && apt-get upgrade -y && \
    apt-get install -y net-tools nano curl unzip sudo cron less

# install aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install

RUN aws configure set default.s3.multipart_threshold 100MB

# prepare working dir
RUN cd / && mkdir workspace
WORKDIR "/workspace"
RUN mkdir backup

# copy files
COPY crontab /etc/cron.d/backup-cron
COPY backup.sh /workspace/backup.sh
COPY entrypoint.sh /workspace/entrypoint.sh

#give permissions for executions
RUN chmod +x /workspace/backup.sh
RUN chmod +x /workspace/entrypoint.sh
RUN chmod 0644 /etc/cron.d/backup-cron

# configure crontab, and create log file for cron job
RUN crontab /etc/cron.d/backup-cron
RUN touch /var/log/backup-cron.log

# command to keep the container running and display cron logs
ENTRYPOINT ["/workspace/entrypoint.sh"]