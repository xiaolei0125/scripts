#!/bin/bash

#docker中要注意mysql与tomcat的启动顺序，确保mysql先启动完成，可以使用：

echo "Start to check mysql import"
date
if [ "$MYSQL_ROOT_PASSWORD" != "" ]; then
    ROOT_PASSWD=$MYSQL_ROOT_PASSWORD
else
   ROOT_PASSWD=123456
fi

var1=50
while [ $var1 -gt 1 ]
do
    echo "For wait mysql, out loop $var1"
    var1=$[ $var1-1 ]

    echo "use mysql" | mysql -uroot -p$ROOT_PASSWD
    RET=$?
    echo "Check mysql, Return is $RET"
    if [ $RET != 0 ]; then
         sleep 5
         continue;
    fi

    echo "use HlPrintSvc" | mysql -uroot -p$ROOT_PASSWD
    RET=$?
    echo "Check HlPrintSvc, Return is $RET"
    if [ $RET != 0 ]; then
        echo "create database IF NOT EXISTS HlPrintSvc" | mysql -uroot -p$ROOT_PASSWD
        echo "source /home/initsql/HlPrintSvc.sql" | mysql -uroot -p$ROOT_PASSWD  HlPrintSvc
        sleep 5
    fi
    break
done
echo "finish check mysql"