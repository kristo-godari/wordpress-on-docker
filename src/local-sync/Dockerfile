FROM ubuntu:latest

RUN apt-get update && apt-get install -y unison

ENTRYPOINT ["unison", "/volume", "/local", "-auto", "-batch", "-repeat", "watch"]