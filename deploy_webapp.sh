

TOMCAT_HOME=/usr/tomcat7
echo "Tomcat Home:$TOMCAT_HOME"
echo "Input:$1"

if [ "$1" != "" ]; then
    WAR_PATH=$1
        echo "Update path"
else
   WAR_PATH=./shopizer/sm-shop/target/sm-shop-2.0.1-SNAPSHOT.war
fi
echo "war package path: $WAR_PATH"

#echo "Sync source code..."
#git pull

echo "Update Evn.."
source /etc/profile

echo "Shutdow tomcat..."
$TOMCAT_HOME/bin/shutdown.sh

if [ "$1" == "build" ]; then
    echo "cd to sub dir.."
    cd ./shopizer
    echo "Start to build project.."
    mvn clean
        echo ""
        echo ""
    mvn package
        cd ../
        WAR_PATH=./shopizer/sm-shop/target/sm-shop-2.0.1-SNAPSHOT.war
fi

echo "Backup old project..."
rm /home/frankie/backup/ebc -rf
mv $TOMCAT_HOME/webapps/ebc /home/frankie/backup/

echo "Start to deploy..."
unzip -oq $WAR_PATH -d $TOMCAT_HOME/webapps/ebc
sleep 1

echo "Start tomcat..."
$TOMCAT_HOME/bin/startup.sh
echo "Finished."
