#!/bin/bash

# DATA_PATH is that data path to install webservr
# Defaut value is /home/laserSvc
DATA_PATH=/home/laserSvc
CONTAINER_NAME=laserSvc
MYSQL_PASSOWRD=123456
DOCKER_IMAGE_ID=42c58affa86c
INSTALL_LOG=/var/log/laserSvcInstall.log

#---------------------------------------
echo "This script will install webserver"
echo "Install Config:"
echo "DATA_PATH      :   $DATA_PATH"
echo "CONTAINER_NAME :   $CONTAINER_NAME"
echo "MYSQL_PASSOWRD :   $MYSQL_PASSOWRD"
echo "DOCKER_IMAGE_ID:   $DOCKER_IMAGE_ID"

echo 
echo "Check Env and tools..."
unzip > $INSTALL_LOG
RET=$?
if [ $RET != 0 ]; then
    echo "Please install unzip tools, now exited"
	exit 1
fi

docker info >> $INSTALL_LOG
RET=$?
if [ $RET != 0 ]; then
    echo "Please install docker or start it, now exited"
	exit 1
fi

docker images | grep $DOCKER_IMAGE_ID
RET=$?
if [ $RET != 0 ]; then
    echo "Please load docker image $DOCKER_IMAGE_ID first..."
	exit 1
fi

#--------------------------------------------
echo
echo "Try to delete old container in case..."
docker stop $CONTAINER_NAME  >> $INSTALL_LOG 2>&1
docker rm $CONTAINER_NAME    >> $INSTALL_LOG 2>&1
	
echo
echo "Create DATA_PATH: $DATA_PATH"
rm $DATA_PATH/* -rf
mkdir -p $DATA_PATH/initsql
mkdir -p $DATA_PATH/mysql
mkdir -p $DATA_PATH/webapps/ROOT
mkdir -p $DATA_PATH/webA


echo
echo "Deploy database and webapps..."
cp ./HlPrintSvc.sql $DATA_PATH/initsql -f
unzip -oq ./base-1.0-SNAPSHOT.war -d $DATA_PATH/webapps/ROOT
unzip -oq ./iPrinter.war -d $DATA_PATH/webapps


echo
echo "Start WebServer Container..."
docker run -d --name $CONTAINER_NAME \
-p 221:22 -p 8080:8080 -p 445:445 -p 137:137 -p 138:138 -p 139:139 \
-v $DATA_PATH:/home -e MYSQL_ROOT_PASSWORD=$MYSQL_PASSOWRD -e StartMANT=mt \
$DOCKER_IMAGE_ID
echo

RET=$?
if [ $RET != 0 ]; then
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
    echo "WebServer install failed, please check env, such as port and path..."
	echo "You can use this script re-install it..."
	exit 1
fi

echo "WebServer Install Success!"
exit 0

