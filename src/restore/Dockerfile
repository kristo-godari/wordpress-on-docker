FROM ubuntu:latest

# update an install packages needed to run and debug
RUN apt-get update
RUN apt-get install net-tools nano curl unzip sudo less -y

# prepare working dir
RUN cd / && mkdir workspace
WORKDIR "/workspace"

# copy files
COPY restore.sh /workspace/restore.sh

# give permissions for executions
RUN chmod +x /workspace/restore.sh

# install aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN sudo ./aws/install


# command to keep the container running and display cron logs
ENTRYPOINT ["/workspace/restore.sh"]