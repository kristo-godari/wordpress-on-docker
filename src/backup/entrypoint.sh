#!/bin/bash

# will put docker environment variables as local environment variables so can be recognized by crontab
# check https://stackoverflow.com/questions/27771781/how-can-i-access-docker-set-environment-variables-from-a-cron-job
printenv | grep -v "no_proxy" >> /etc/environment

# will not let the container to die
cron -f