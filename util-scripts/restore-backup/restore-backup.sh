# start restore container
docker-compose up

docker restart ${sitename.com}-database
docker restart ${sitename.com}-webserver