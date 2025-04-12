# WordPress on Docker and HTTP-3

## Introduction
WordPress on Docker is a project that aims to provide a simple architecture and deployment solution for running WordPress on HTTP-3 on a production server using Docker.
It's designed with the development process in mind, to make it easy for a single developer or a small team, to develop, deploy, and maintain this project in the long run.

Feel free to submit improvements as Pull Requests. For sure this project can be improved further.
<br/><br/>
Don't like reading, want some action, jump to: [Use Cases](#use-cases)

## How to use
This project is meant to be added as a git submodule to your website repo. This website repo needs to have a specific structure. 
Check example structure here: [WordPress on Docker - Website Repository Example](https://github.com/kristo-godari/wordpress-on-docker-website-repo-example) 

## Conceptual design
Check out the conceptual design here: [Conceptual Design](docs/conceptual-design.md) to understand the big picture.

## Prerequisite for development
- Have Docker installed
- Have Ansible installed

## Prerequisite for running this project in production
*At some point, this can be automated as well, but for the moment is one time manual setup.*
- Have a Virtual machine somewhere
  - create a user for that machine.
  - configure ssh for that user.
- Have a domain name
  - Configure domain name dns to point to the IP address of your virtual machine.
- Have an SSL certificate valid for that domain
    - you need to have both the certificate and the private key.
- Have an AWS account
  - create a s3 bucket with your domain name.
  - create aws credentials to read/write from that s3 bucket.
- Have a Docker Hub account 
  - create a private repository for your domain.

## Conscious design decisions
- In docker hub, I have saved all my images in one private repository and separated them by tag, and names. 
  - username/repository-name:sitename.com-database
  - username/repository-name:sitename.com-webserver
  - where repository-name is my repository name, and sitename.com-database is the tag name. 
  - This might not be the optimal solution, but it works perfectly fine, since i don't want to pay for docker repositories, and don't want to expose my docker images publicly.
  - Anyway, if your situation is different, feel free to change this. They are also other containers registry providers, that allow you to have multiple repositoreis for free.
- In S3, we have the following bucket structure:
  - /domain-name.com
    - env
      - backups
        - webserver
          - webserver-backup.tar
        - database
          - database-backup.tar
  - During backup, the existing backup is overridden by the new backup. I decided to do this for two reasons:
    - I did not have a need to keep a history of backups, but I am always interested having the latest backup.
    - Backup is done daily, and the space can grow very quickly, if you are not careful, and amazon will start to charge you.

## Project structure explained
- ansible - contains ansible files
  - playbooks - contains ansible playbooks
    - build-docker-images.yaml: ansible playbook for building docker images
    - deploy-docker-containers.yaml: ansible playbook for deploying docker containers
    - build-docker-volumens.yaml: ansible playbook for building docker volumes
    - publish-docker-images.yaml: ansible playbook for publishing docker images to docker hub
    - backup-docker-volumes.yaml: ansible playbook for backing up docker volumes
    - deploy-docker-volumes.yaml: ansible playbook for deploying docker volumes
    - stop-and-remove-containers.yaml: ansible playbook for stopping and removing containers
  - roles - contains ansible roles
- docs
  - documentation files
- src - source code files for building images
  - backup - container executing the backup of volumes
  - database - database container
  - database-admin-ui - database admin ui container
  - local-sync - container to sync volume files to a local folder
  - restore - container restoring backup of volumes
  - webserver - webserver container
    - webserver-config - webserver configuration files
      - folder will be copied inside container
    - website-files - website files
      - folder will be copied inside container

## Good to know
- Under src/webserver/website-files you will find the following files
  - .htaccess is needed at the root of your webserver for WordPress to work properly. By default, the permalinks will not work in WordPress. Litespeed will say that it does not find this file. To fix this a custom src/webserver/website-files/.htaccess is copied inside the container
  - wp-config.php is adapted, to take values for env variables, this will replace the deafault wp-config.php that comes with wordpress. If you need any changes there, make sure you modify them here as well.
  - When you deploy to prod, you deploy the new container, but the existing volumes are reused. So all the existing files should be there. 

## Use cases
Note: Below i provide the steps so you understand the process, but all those steps can be automated using github actions, or bitbucket pipeline.

### Starting from schratch / New website creation
- Navigate to `ansible` directory
- Run `ansible-playbook playbooks/build-docker-images.yaml`. This will build all docker images.
- Then run `ansible-playbook playbooks/build-docker-volumes.yaml`. This will build the initial docker volumes.
- Then run `ansible-playbook playbooks/deploy-docker-containers.yaml -e "env=local"`. This will deploy docker containers locally.
  - env can take the following values: local, prod
- At this point we have containers, and volumes, we can test locally, follow the section [Local Testing](#local-testing) from below, and once you finished there you can continue with next steps here.
- Setup wordpress, configure it, install plugins, themes, add content etc... 
- Once you are happy with the results, and everyting is working you can publish docker images to docker hub, by running: `ansible-playbook playbooks/publish-docker-images.yaml`
- Once you are ready, or you want to save the progress, you can run: `ansible-playbook playbooks/backup-docker-volumes.yaml -e "env=local version=local"` or `ansible-playbook playbooks/backup-docker-volumes.yaml -e "env=local version=dev"`
  - This will backup your volumes, in S3 under the local or dev folder. Local if you want to save work for latter, dev if you want to proceed with the prod deployment.
- To delploy in production we need:
  - First we need to install docker on the VM (only if not installed already): `ansible-playbook playbooks/install-docker-on-ubuntu.yaml`
  - First to have voumes from dev, by running: `ansible-playbook playbooks/deploy-docker-volumes.yaml  -e "env=prod version=dev"`
  - Then to deploy containers with running: `ansible-playbook playbooks/deploy-docker-containers.yaml  -e "env=prod"`
- Now uncomment the `127.0.0.1 your-domain-name.com` from `etc/hosts` so we can redirect traffic to the production server.
- Voilà, now you have the website up and running in production. 

### Maitenance Docker Image Update
- Modify docker images source files from `src` folder
- Run `ansible-playbook playbooks/build-docker-images.yaml`. This will build the new docker images.
- Test locally the new images 
- Publish image to docker hub by running: `ansible-playbook playbooks/publish-docker-images.yaml`
- Update deployment ansible playbook if needed in: `deploy-docker-containers.yaml`
- Replace prod containers with new ones, by running: `ansible-playbook playbooks/deploy-docker-containers.yaml -e "env=prod"`

### SSL Certificate Update / Wordpress Update / Files Update etc..
- Update files from the source git repo, with new certificates, file modification etc...
- Build new volumes by running `ansible-playbook playbooks/build-docker-volumes.yaml` 
- Backup thew new volumes to S3 dev by running: `ansible-playbook playbooks/backup-docker-volumes.yaml -e "env=local version=dev"`
- Deploy new volumes to prod, by restoring form s3 dev: `ansible-playbook playbooks/deploy-docker-volumes.yaml  -e "env=prod version=dev"`
- Restart prod containers with new volumes by running: `ansible-playbook playbooks/deploy-docker-containers.yaml  -e "env=prod"`

## Local testing
- Run `ansible-playbook playbooks/deploy-docker-containers.yaml  -e "env=local"` to start containers locally
  - This will run docker containers, and attach the volumes created above. By this point you have the infrastructue up and running. 
- Before accessing your website from the browser, we need to adjust the `etc/hosts` file by running `vim /etc/hosts` to add a new rule `127.0.0.1 your-domain-name.com`
  - Replace your-domain-name.com with your real domain name. 
  - Since we are running docker containers locally, this is needed to redirect traffic locally.
  - This is also needed, since webserver is configured with your domain name. And also the browser will match the ssl certificate with domain names, so it can show that the website is secure. 
- Access the site from browser: https://your-domain-name.com 
  - Using https://127.0.0.01 will get you 404 since the webserver is configured only with your domain name.

## Backups
- Backups are set up to run daily at 05:04 in the morning. You can change this in the src/backup/crontab file.
- Backups location in S3 is determined by $DOCKER_VOLUME_VERSION environment variable, make shure is set correct. Otherwise you can override production backup with dev backup, and vice versa.
  - By default if nothing specified the DOCKER_VOLUME_VERSION=local for saftey reasons.

## Restore
- Restore will connect to S3, get the latest backup, connect to docker volumes, and restore the files from the backup.
- It's important to restart the containers after this happens.
- You can use this to restore a production backup locally, so you can work on the latest production code, and data.
  - In my case, I don't have customer or sensitive data on my website, and I can easily work with production data locally.

## Troubleshooting
During my development and setup, sometimes things were not working as expected, and it is likely that you will face those issues too. I have taken notes on how I have solved them:
- Site content is not updated after you build and deploy a new container.
  - This is because the old content is still in the docker volumes. Docker volumes needs to be deleted and cleaned up.
  - Mysql credentials will not work, if you change them. Since they are stored in the volume. Delete volume, and start over.
- Webserver files and configuration are copied inside docker container. 
  - If you make any changes to those you need to build again your docker image.
- Make sure your bucket exist on aws, otherwise backup will not work.
- Sometimes you need to delete and cleanup the network, if you play with network name changes. 
- SSH key file needs to have permissions setup to 600 
- In case you want to tweak php, in the container is installed under: /usr/local/lsws/lsphp81/bin
- You will need to put a custom .htaccess at the root of your webserver for WordPress to work properly.
  - By default, the permalinks will not work in WordPress. Litespeed will say that it does not find this file.
  - To fix this a custom src/webserver/website-files/.htaccess is copied inside the container
- Make sure wp-config.php is set up properly. 
  - We have a custom wp-config.php in src/webserver/website-files/wp-config.php. Make sure this is copied properly.  
- By default, the settings of php.ini are very restrictive and if you will try to upload a theme that is
  a little big, and requires more time to process you will not be able to do this.
  To fix this problem you need to:
  -  login to docker container `docker exec -it CONTAINER_NAME/ID sh`
  -  locate php.ini file in directory `/usr/local/lsws/lsphp81/etc/php/8.1/litespeed`
  -  modify php.ini propeties
      - sed -i '/upload_max_filesize/c\upload_max_filesize = 128M' php.ini
      - sed -i '/post_max_size/c\post_max_size = 128M' php.ini
      - sed -i '/max_execution_time/c\max_execution_time = 1000' php.ini
  - restart php module `killall -9 lsphp`
  - reference https://pieterbakker.com/edit-php-ini-settings-for-openlitespeed/
