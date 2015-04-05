#!/bin/bash
PROJECT=nginx
ACCOUNT=infrabricks
RELEASE_TAG=1.7.11-docker
docker build -t="$ACCOUNT/$PROJECT" .
DATE=`date +'%Y%m%d%H%M'`
ID=$(docker inspect -f "{{.Id}}" $ACCOUNT/$PROJECT)
docker tag -f $ID $ACCOUNT/$PROJECT:latest
docker tag -f $ID $ACCOUNT/$PROJECT:$DATE
docker tag -f $ID $ACCOUNT/$PROJECT:$RELEASE_TAG
