# move to build directory
cd build

# build images
docker-compose build

# login to docker hub
docker login

# push images
docker-compose push