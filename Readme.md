# WordPress on Docker and HTTP-3

## Introduction
WordPress on Docker is a project that aims to provide a simple architecture and deployment solution for running WordPress on HTTP-3 on a production server using Docker.
It is a very technical project, with a lot of technologies, but it provides you with the flexibility to fine-tune every aspect of the solution if you need it. 
It's designed with the development process in mind, to make it easy for a single developer or a small team, to develop, deploy, and maintain this project in the long run.

I could have just paid for a managed WordPress solution, but I'm the kind of guy who likes to learn and build stuff. 
And while I have learned a lot from building this project, I have also had a lot of fun. 

Feel free to submit improvements as Pull Requests. For sure this project can be improved further.
<br/><br/><br/>
Don't like reading, want some action, jump to: [Setup procedure](#setup-procedure)

## Conceptual design
Check out the conceptual design here: [Conceptual Design](docs/conceptual-design.md)

## Prerequisite for running this project in production
- Have a Virtual machine somewhere
  - create a user for that machine.
  - configure ssh for that user.
  - install docker on that machine.
  - install docker compose on that machine.
  - login in your docker hub account in order to pull images (if the repository is private).
  - crate a /workspace directory and make it owned by the current user.
- Have a domain name
  - Configure domain name dns to point to the IP address of your virtual machine.
- Have an SSL certificate valid for that domain
    - you need to have both the certificate and the private key.
- Have an AWS account
  - create a s3 bucket with your domain name.
  - create aws credentials to read/write from that s3 bucket.
- Have a Docker Hub account 
  - create a private repository for your domain.

## Costs for running this project in production
Costs will vary depending on the provider, and the machine specs but here is what currently I pay for mine:
- Virtual machine:  6 euro/month (4 cores, 8 GB Ram, 200 GB (100% SSD), Unlimited BandWith). 78$/year 
- Domain name: 15$/year. 
- SSL certificates: 13$/year.
- S3 storage: free, by using the free tier.
- Docker hub: free, by using only one private repository.

Total: ~106$/year, which is a good price, the average price for a managed WordPress(4 cores, 8 GB Ram) is ~700$/year.  

## Conscious design decisions
- In docker hub, I have saved all my images in one private repository and separated them by tag, and names. 
  - kristogodari/general-private:${sitename.com}-database
  - kristogodari/general-private:${sitename.com}-webserver
  - where general-private is my repository name, and kristogodari.com-database is the tag name. 
  - This might not be the optimal solution, but it works perfectly fine, since i don't want to pay for docker repositories, and don't want to expose my docker images publicly.
  - Anyway, if your situation is different, feel free to change this.
- In S3, we have the following bucket structure:
  - /domain-name.com
    - backups
      - webserver
        - webserver-backup.tar
      - database
        - database-backup.tar
  - During backup, the existing backup is overridden by the new backup. I decided to do this for two reasons:
    - I did not have a need to keep a history of backups, but I am always interested having the latest backup.
    - Backup is done daily, and the space can grow very quickly, if you are not careful, and amazon will start to charge you.

## Project structure explained
- cicd - continuous integration and continuous delivery
  - build
    - docker compose files used to build the images
    - env files, used to provide variables to docker compose
  - deploy
    - common
      - common files for both deployments
      - docker compose files to start docker containers
      - common env variables, used to provide variables to docker compose
    - local
      - environment variables used to deploy locally
    - production
      - environment variables used to deploy in production
    - scripts to build and deploy
- docs
  - documentation files
- src - source code files for building containers
  - backup - backup container
  - database - database container
  - database-admin-ui - database admin  ui container
  - restore - restore container
  - webserver - webserver container
    - cert - ssl certificates
      - folder will be copied inside container
    - config - webserver configuration files
      - folder will be copied inside container
    - sites - website files
      - folder will be copied inside container
- util-scripts
  - docker
    - util scripts for managing containers
  - restore-backup
    - docker compose files for starting the restore container
    - env variables for restore container
    - scripts to start the restore container

## Customization
- This projects comes with the WordPress version 6.1.1. 
  - However, if another version is needed, this can be easily done by placing all files under the src/web-server/sites/${sitename.com}/html folder.
  - Just make sure that wp-config.php and .htaccess are set up properly
- This project is not restricted to WordPress, any web project can run with this.
  - The only restriction is given by Litespeed webserver. Check what is supported on the official website: https://openlitespeed.org/
- You can customize almost any aspect of this project, by modifying the appropriate files.

## Setup procedure
- Search and replace in all the files and folders (except Readme files) in this repo for:
  - ${sitename.com} -> replace this with your site name ex: kristogodari.com
  - ${mysql-root-password} -> your desired mysql root password
  - ${mysql-user} -> your desired mysql user
  - ${mysql-password} -> your desired mysql password
  - ${litespeed-admin-user} -> your desired admin user
  - ${litespeed-admin-password} -> your desired admin password
  - ${aws-access-key} -> your aws access key
  - ${aws-secret} -> your aws secret for access key
  - ${docker-hub-repository}-> your docker hub, private repository ex: username/general-private
  - ${ssh-server-ip} -> The ip of your production virtual machine.
  - ${ssh-user} -> SSH user that will be used to connect to your production virtual machine.
  - ${ssh-key-phase-phrase} -> SSH phase phrase if your ssh key is set up with key protection.
- Ssh keys 
  - Put your own ssh private key at: cicd/deploy/production/ssh/ssh-key
  - Put your own ssh public key at: cicd/deploy/production/ssh/ssh-key.pub 
- SSL certificates
  - Put your own ssl certificate at:  src/web-server/cert/webadmin.crt
  - Put your own ssl certificate key at: src/web-server/cert/webadmin.key
- Folder renaming
  - Rename src/web-server/config/vhosts/${sitename.com} folder with your site name ex: kristogodari.com
  - Rename src/web-server/sites/${sitename.com} folder with your site name ex: kristogodari.com
- wp-config.php and .htaccess (only if website is WordPress)
  - copy docs/wordpress/.htaccess to src/web-server/sites/${sitename.com}/html
  - copy docs/wordpress/wp-config.php to src/web-server/sites/${sitename.com}/html 
    - make sure you replace variables like ${sitename.com}, ${mysql-user}, ${mysql-password} as well.

## Backups
- Backups are setup to run daily at 05:04 in the morning. You can change this in the crontab file.
- Backup is done only if you deploy with the "prod" profile. If you test locally, backup will not work, since deployment is done with the "local" profile.
  - This is intentional since I ended up overriding the production backup a couple of times, with my local work.
- Sometimes you develop locally, and have the latest version of your data locally, and you want to put this in prod. You can easily accomplish this by:
  - Backup your work to s3
  - Login to the production server and restore the backup

## Restore
- Restore will connect to s3, get the latest backup, connect to docker volumes, and restore the files from the backup.
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
  - To fix this you copy docs/wordpress/.htaccess to src/web-server/sites/${sitename.com}/html
- Make sure wp-config.php is set up properly. 
  - Check that "Custom settings for SSL support" are set up. You have an example at docs/wordpress/wp-config.php
  - Check database connectivity settings.
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