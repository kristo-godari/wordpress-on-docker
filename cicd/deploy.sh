deploy_locally () {
    # copy docker compose to local directory and move there
    cp ./deploy/common/docker-compose.yml ./deploy/local
    cd ./deploy/local

    # stop old containers and remove them
    docker stop $(docker ps -aq)
    docker rm $(docker ps -aq)

    # start new containers
    docker-compose up -d
    docker ps

    # remove docker compose file from local folder
    rm docker-compose.yml
}


deploy_prod(){

  # copy docker compose to prod directory and move there
  cp ./deploy/common/docker-compose.yml ./deploy/production
  cd ./deploy/production


  # load ssh config as env variables
  export $(grep -v '^#' ./ssh/ssh-config.env | xargs)

  # create website directory
  ssh $SSH_USER@$SSH_SERVER_IP "cd /workspace && rm -rf $DOMAIN_NAME  && mkdir $DOMAIN_NAME"

  # copy files
  scp ./.env $SSH_USER@$SSH_SERVER_IP:/workspace/$DOMAIN_NAME
  scp docker-compose.yml $SSH_USER@$SSH_SERVER_IP:/workspace/$DOMAIN_NAME

  # fresh clean, stop, delete containers, remove images, fetch all from the repository
  ssh $SSH_USER@$SSH_SERVER_IP "cd /workspace/$DOMAIN_NAME && docker stop \$(docker ps -aq)"
  ssh $SSH_USER@$SSH_SERVER_IP "cd /workspace/$DOMAIN_NAME && docker rm \$(docker ps -aq)"
  ssh $SSH_USER@$SSH_SERVER_IP "cd /workspace/$DOMAIN_NAME && docker rmi \$(docker images -aq)"
  ssh $SSH_USER@$SSH_SERVER_IP "cd /workspace/$DOMAIN_NAME && docker-compose up -d"
  ssh $SSH_USER@$SSH_SERVER_IP "cd /workspace/$DOMAIN_NAME && docker ps"

  # remove docker-compose from current directory
  rm docker-compose.yml
}

# load deployment config as env variables
export $(grep -v '^#' ./deploy/common/deployment-config.env | xargs)

# based on the environment run one of the deployment functions
DEPLOYMENT_ENV=$1
if [ $DEPLOYMENT_ENV = "local" ]; then
  deploy_locally
elif [ $DEPLOYMENT_ENV = "prod" ]; then
  deploy_prod
else
  echo "No environment provided. Run 'deploy.sh local' or 'deploy.sh prod'"
fi
