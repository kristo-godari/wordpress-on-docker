FROM ubuntu:22.10

# update an install packages
RUN apt-get update
RUN apt-get install net-tools nano curl unzip sudo cron less -y

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

# install aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN sudo ./aws/install

# configure crontab, and create log file for cron job
RUN crontab /etc/cron.d/backup-cron
RUN touch /var/log/backup-cron.log

# command to keep the container running and display cron logs
ENTRYPOINT ["/workspace/entrypoint.sh"]