#!/bin/bash

Sync_DependantCode()
{
    cd $WORKSPACE/
    echo " "
    
    cd ../CBIOS/elite_cbios_trunk_4.4/
    echo "Started to sync code on $PWD ..."
    git pull
   
    cd $WORKSPACE/
}

Create_Package_Path()
{
    BUILD_RESULT_PATH=/home/build_result/$GERRIT_CHANGE_NUMBER
    PROJECT_RESULT_PATH=$BUILD_RESULT_PATH/${JOB_NAME##*/}
    echo "Prepared package path: $PROJECT_RESULT_PATH"
    if [ ! -d "$BUILD_RESULT_PATH" ]; then
        echo "$BUILD_RESULT_PATH is'nt exist, Creating it..."
        mkdir -p $BUILD_RESULT_PATH
    fi

    if [ ! -d "$PROJECT_RESULT_PATH" ]; then
        echo "$PROJECT_RESULT_PATH is'nt exist, Creating it..."
        mkdir -p $PROJECT_RESULT_PATH
    fi

    if [ -d "$PROJECT_RESULT_PATH" ]; then
        echo "$PROJECT_RESULT_PATH Prepared Successful."
    else
        echo "$PROJECT_RESULT_PATH Prepared Failed"
    	exit 1
    fi
}

Release_Package()
{
    echo "Started to Release Driver Package..."
	# cp -rf /home/codespace/s3gdrv/elite_gfx_drv_trunk_4.4/Android/android_package  $PROJECT_RESULT_PATH/
    cp -rf  $WORKSPACE/Android/s3g-android-*-Elt.tar.bz2  $PROJECT_RESULT_PATH/
    
    
    echo "Starting to Check Driver Package..."
    cd  $PROJECT_RESULT_PATH/
    DRV_PACKAGE_NAME=$(ls s3g-android-*-Elt.tar.bz2 | sed 's/.tar.bz2//g')
    echo "Detected driver package name: $DRV_PACKAGE_NAME"
    if [ -z "$DRV_PACKAGE_NAME" ]; then
        echo "Failed to detected driver package name, now exit..."
        # exit 1
    fi
    tar -xjf  $PROJECT_RESULT_PATH/$DRV_PACKAGE_NAME.tar.bz2
    
    echo "Delete zImage/uImage..."
    rm $PROJECT_RESULT_PATH/$DRV_PACKAGE_NAME/zImage
    rm $PROJECT_RESULT_PATH/$DRV_PACKAGE_NAME/uImage
    
    tar -cjf $DRV_PACKAGE_NAME-simple.tar.bz2  $DRV_PACKAGE_NAME/
    sync
    rm -rf $DRV_PACKAGE_NAME
    cd -
}

Write_ProjectInfo()
{  
    echo "Started to write project info...."
    
	echo "Project Information:  "  >   $PROJECT_INFO_FILE   
	echo "Project Name   : $GERRIT_PROJECT"  >>  $PROJECT_INFO_FILE
    echo "Project Job    : $DEF_JOB_NAME "  >>  $PROJECT_INFO_FILE
	echo "Project Owner  : $GERRIT_CHANGE_OWNER_EMAIL"  >>  $PROJECT_INFO_FILE
    
    echo "Change Number  : $GERRIT_CHANGE_NUMBER "  >>  $PROJECT_INFO_FILE
    echo "Change URL     : $GERRIT_CHANGE_URL"  >>  $PROJECT_INFO_FILE
    echo "Change ID      : $GERRIT_CHANGE_ID"  >>  $PROJECT_INFO_FILE
    echo "Change Subject : $GERRIT_CHANGE_SUBJECT"  >>  $PROJECT_INFO_FILE
    echo "Change Email   : $GERRIT_PATCHSET_UPLOADER_EMAIL"  >>  $PROJECT_INFO_FILE
    
}

Write_Build_Result()
{
    AUTOBUILD_RESULT_LOG=$BUILD_RESULT_PATH/autobuild_result.log
    PROJECT_INFO_FILE=$AUTOBUILD_RESULT_LOG
    DEF_JOB_NAME="All"
    
    if [ ! -f "$AUTOBUILD_RESULT_LOG" ]; then
        Write_ProjectInfo
        echo " " >> $AUTOBUILD_RESULT_LOG
        echo "Autobuild Result:  " >> $AUTOBUILD_RESULT_LOG
    fi

	if [  $RET = 0 ]; then
        echo "${JOB_NAME##*/}:  Success." >> $AUTOBUILD_RESULT_LOG
    else
        echo "${JOB_NAME##*/}:  Failed.!!!. Please Check...."  >> $AUTOBUILD_RESULT_LOG
    fi
    
}

Exit_withCheck()
{
# gerrit review <CHANGE>,<PATCHSET> --message 'Build Successful <BUILDS_STATS>'  --code-review <CODE_REVIEW>
# gerrit review <CHANGE>,<PATCHSET> --message 'Build Failed <BUILDS_STATS>'  --code-review <CODE_REVIEW>

	LINK=http://10.5.63.59/$GERRIT_CHANGE_NUMBER/${JOB_NAME##*/}/
    
    if [ $1 -eq 2 ]; then
       ssh -p 29418 Jenkins@10.5.253.119 gerrit review -m '"Sorry, Auto Build System Error..."' $GERRIT_PATCHSET_REVISION  --code-review +0
    elif [ $1 -eq 0 ]; then
       echo "Build Successful. pls refer to $LINK"
       MSG="\"Build Successful: $LINK \""
       ssh -p 29418 Jenkins@10.5.253.119 gerrit review -m  $MSG  $GERRIT_PATCHSET_REVISION  --code-review +1
    else 
       MSG="\"Build Failed: $LINK \""
       ssh -p 29418 Jenkins@10.5.253.119 gerrit review -m  $MSG  $GERRIT_PATCHSET_REVISION  --code-review -1
    fi   
  
    exit $1
}

# ----------------------------------------------

echo " "
echo "Autobuild jobs starting..."
echo "Job Name: ${JOB_NAME##*/} "
echo "WorkSpace: $WORKSPACE "

Create_Package_Path
Sync_DependantCode

echo " "
echo "Start to run build script..."
RET=2
cd ./Android
echo "jenkins" | sudo -Ss ./build_android_gfx_drv.sh  +4.4 >  $PROJECT_RESULT_PATH/autobuild_log_for_driver_v4.4.log  2>&1
RET=$?
echo "Finish to run build script with result: $RET."


if [  $RET = 0 ]; then
	Release_Package
    echo "Current project job autobuild success!" > $PROJECT_RESULT_PATH/autobuild_Success.log
else
    echo "Current project job autobuild failed!" > $PROJECT_RESULT_PATH/autobuild_Failed.log
fi

Write_Build_Result

PROJECT_INFO_FILE=$PROJECT_RESULT_PATH/project_info.log
DEF_JOB_NAME=${JOB_NAME##*/}
Write_ProjectInfo

echo "Autobuild jobs is finished.Result is: $RET"
//exit $RET
Exit_withCheck $RET
# ----------------------------------------------