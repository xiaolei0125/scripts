#!/bin/bash

echo "This script will update webserver"

# DATA_PATH is that data path to install webservr
# Defaut value is /home/laserSvc
DATA_PATH=/home/laserSvc
CONTAINER_NAME=laserSvc
INSTALL_LOG=/var/log/laserSvcInstall.log

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


echo "Stop webserver container..."
docker stop $CONTAINER_NAME

echo "Backup image for webapps..."
mv $DATA_PATH/webapps/ROOT/image $DATA_PATH/webapps/
echo "Update webapps..."
rm $DATA_PATH/webapps/* -rf
mkdir -p $DATA_PATH/webapps/ROOT
unzip -oq ./base-1.0-SNAPSHOT.war -d $DATA_PATH/webapps/ROOT
unzip -oq ./iPrinter.war -d $DATA_PATH/webapps
echo "Restore image for webapps..."
mv $DATA_PATH/webapps/image $DATA_PATH/webapps/ROOT/

echo "Start webserver container..."
docker start $CONTAINER_NAME

RET=$?
if [ $RET != 0 ]; then
    docker stop $CONTAINER_NAME
    echo "WebServer Start failed, please check env..."
	exit 1
fi
echo "WebServer update Success!"
exit 0

