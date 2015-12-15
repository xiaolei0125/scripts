#!/bin/bash

if [ "$1" = "" ] ; then
    DRV_SRC=/home/jenkins/android_autotest/s3g-android-52.02.01-Elt
    #DRV_SRC=/root/android-rootfs/s3g-android-52.02.01-Elt
else
    DRV_SRC=$1
fi

if [ "$2" = "" ] ; then
    #DEV_IP=10.3.44.51
    DEV_IP=192.168.0.100
else
    DEV_IP=$2
fi

if [ "$3" = "" ] ; then
    SCRIPT_ENV_PATH=/home/jenkins/android_autotest
else
    SCRIPT_ENV_PATH=$3
fi

DEV_ID=$DEV_IP:5555
DRV_DST=/s3g_drv

check_env()
{
  echo "Checking scripts evn: $SCRIPT_ENV_PATH"
  if [ ! -f "$SCRIPT_ENV_PATH/install_online.sh" ]; then
     echo "Error: $SCRIPT_ENV_PATH/install_online.sh is not exist. Now exit..."
     exit 2
  fi

  if [ ! -f "$SCRIPT_ENV_PATH/pu" ]; then
     echo "Warning: $SCRIPT_ENV_PATH/pu is not exist..."
  fi
}

adb_lock()
{
    echo " "
    for((i=0; i<120; i++))
    do 
        if [ -f $SCRIPT_ENV_PATH/adb.lock ]; then
            echo "adb is locked by others, wait 10 sec for $i times..."
            sleep 10
            continue
        else
            touch $SCRIPT_ENV_PATH/adb.lock
            echo "Lock adb succesful..."
            break
        fi
    done 

    if [ $i -eq 120 ]; then
        echo "Faied to lock adb for $i times, now program exit..."
        exit 2
    fi
}

adb_unlock()
{
    echo " "
    echo "Disconnect from $DEV_IP..."
    adb disconnect $DEV_IP

    if [ -f $SCRIPT_ENV_PATH/adb.lock ]; then
        echo "Unlock adb..."
        rm $SCRIPT_ENV_PATH/adb.lock
    fi
}

adb_exit()
{
    adb_unlock

    echo "adb script exit with $1"
    exit $1 
}

adb_connect()
{
    echo "Ready to connect adb devices..."
    adb kill-server
    adb start-server
    sleep 2
    adb connect $DEV_IP
#    sleep 1
#    adb connect $DEV_IP
    sleep 1
    adb -s $DEV_ID root
    sleep 1
    adb connect $DEV_IP
    sleep 1
#    adb connect $DEV_IP
    DEV_STATUS=$(adb get-state)
    echo "Devices status: $DEV_STATUS"
    if [ $DEV_STATUS = "device" ]; then
        echo "Connected devices $DEV_ID successful."
    else
        echo "Failed to connect devices $DEV_ID."
        $SCRIPT_ENV_PATH/pu push Chrome   note "Adb connect Failed:"  "IP: $DEV_IP   From: $DRV_SRC"
        $SCRIPT_ENV_PATH/pu push LG-VS980 note "Adb connect Failed:"  "IP: $DEV_IP   From: $DRV_SRC"
        adb_exit 2
    fi
    echo " "
}

adb_usb_detect()
{
    echo "Ready to detect usb adb devices..."
}


echo " "
echo "Android Dev ID:  $DEV_ID"
echo "Current Path  :  $(pwd)"
echo "Driver Package:  $DRV_SRC"

check_env
adb_lock
adb_connect

sleep 3
echo "Starting to check local driver package..."
if [ ! -d "$DRV_SRC" ] ; then
    echo "Error: Local driver package doesn't exist."
    adb_exit 2
fi
cp -p $SCRIPT_ENV_PATH/install_online.sh $DRV_SRC

echo "Starting to delete and re-create $DRV_DST on android..."
adb -s $DEV_ID shell rm -rf $DRV_DST
adb -s $DEV_ID shell mkdir  $DRV_DST

echo "Starting to push driver files to android..."
adb -s $DEV_ID push $DRV_SRC $DRV_DST >  $DRV_SRC/AdbPushFiles.log  2>&1

echo "Starting to change driver files attributes..."
adb -s $DEV_ID shell chown system:system $DRV_DST/*
adb -s $DEV_ID shell chmod 755 $DRV_DST/*
adb -s $DEV_ID shell chmod 644 $DRV_DST/*.ko

echo "Starting to install driver on android..."
adb -s $DEV_ID shell $DRV_DST/install_online.sh $DRV_DST
adb -s $DEV_ID shell sync
echo "Finished to install driver on android."
sleep 15

echo " "
echo "Starting to reboot android os..."
adb reboot &
ADBPID=$(pidof -s adb reboot)
echo "Find out adb reboot program pid: $ADBPID"
sleep 4
kill -9 $ADBPID
echo "Device $DEV_ID is rebooting..."

sleep 2
adb_unlock

echo "Waiting for android reboot finished..."
sleep 60


adb_lock
adb_connect


DIS_MODE_INFO=$(adb -s $DEV_ID shell dmesg | grep "set mode on IGA")
echo "Detected display mode info: $DIS_MODE_INFO"
DIS_POWER_INFO=$(adb -s $DEV_ID shell dmesg | grep "Power ON device")
echo "Detected display power info: $DIS_POWER_INFO"
if [ -z "$DIS_MODE_INFO" ] || [ -z "$DIS_POWER_INFO" ] ; then
   echo "Detected s3g graphics boot failed."
   echo "Android devices reboot failed"
   adb_exit -1
fi

echo " "
PID_EXIT_INFO=$(adb -s $DEV_ID shell dmesg | grep "init: untracked pid")
echo "Detected untracked pid exit info: $PID_EXIT_INFO"
PID_EXIT_INFO5=$(echo $PID_EXIT_INFO | sed -n '5,6p')
echo "Check pid exit info beyond 5: $PID_EXIT_INFO5"


TRACK_PID_INFO=$(adb -s $DEV_ID shell logcat -d | grep "init: untracked pid")
echo $TRACK_PID_INFO

EGL_INFO=$(adb -s $DEV_ID shell logcat -d | grep "loaded /system/lib/egl/libEGL_s3g.so")
echo "Detect EGL load info: $EGL_INFO"
if [ -z "$DIS_MODE_INFO" ]; then
    echo "Detect EGL load info faild"
    echo "Android devices reboot failed"
    adb_exit -1
fi

LAUNCHER_INFO=$(adb -s $DEV_ID shell logcat -d | grep "Start proc com.android.launcher for activity")
echo "Detect lanucher info: $LAUNCHER_INFO"
if [ -z "$LAUNCHER_INFO" ]; then
    echo "Detect launcher info faild"
    echo "Android devices reboot failed"
    adb_exit -1
fi

echo " "
echo "Android devices reboot successful."
echo " "

adb_exit 0
