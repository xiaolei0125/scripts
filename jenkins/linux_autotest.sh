#!/bin/bash

REMOTE_JOB_NAME=$(echo "${JOB_NAME##*/}" | sed 's/Test_//g')
REMOTE_PROJECT_RESULT_PATH=/home/build_result/$GERRIT_CHANGE_NUMBER/$REMOTE_JOB_NAME
REMOTE_DRV_PACK_PATH=$REMOTE_PROJECT_RESULT_PATH/s3g-android-*-Elt-simple.tar.bz2

IS_PACKAGE_LOCAL=yes
TEST_RESULT_PATH=/home/build_result/$GERRIT_CHANGE_NUMBER
TEST_PROJECT_PATH=$REMOTE_PROJECT_RESULT_PATH
#TEST_RESULT_PATH=/home/jenkins/android-autotest/$GERRIT_CHANGE_NUMBER
#TEST_PROJECT_PATH=$TEST_RESULT_PATH/${JOB_NAME##*/}
	
AUTOTEST_RESULT_LOG=$TEST_RESULT_PATH/Auto_Test_Result.log
AUTOTEST_PROJECT_CONF=$TEST_PROJECT_PATH/Auto_Test.conf
TEST_PROJECT_TAG=AutoTest_For_$REMOTE_JOB_NAME

AUOTTEST_ENV_PATH=/home/jenkins/android_autotest
AUTOTEST_SCRIPT=android_auto_test.sh
TARGET_DEV_ID=10.3.36.39


Exit_withCheck()
{
    if [ $1 -eq 2 ]; then
       ssh -p 29418 Jenkins_test@10.5.253.119 gerrit review -m '"Sorry, Auto Test System Error..."' $GERRIT_PATCHSET_REVISION  --code-review +0
    elif [ $1 -eq 0 ]; then
       echo "Exit Successful."
    else   
       ssh -p 29418 Jenkins_test@10.5.253.119 gerrit review -m '"Test Failed"' $GERRIT_PATCHSET_REVISION  --code-review -1    
    fi   

    echo "Update Auto Test Conf..."
    if [ -f "$AUTOTEST_PROJECT_CONF" ]; then
        rm -f $AUTOTEST_PROJECT_CONF
    fi
    echo "$GERRIT_PATCHSET_REVISION" >   $AUTOTEST_PROJECT_CONF
    echo "$1" >>  $AUTOTEST_PROJECT_CONF

    echo "Exit with value: $1" 
    exit $1
}
	
Get_Drv_Package()
{
    echo "Starting to get driver package..."
    
    if [ "$IS_PACKAGE_LOCAL" = "no" ]; then
        echo "Get driver package from remote auto build server..."
        scp  jenkins@10.5.63.59:$REMOTE_DRV_PACK_PATH  $TEST_PROJECT_PATH
    fi
    
    cd $TEST_PROJECT_PATH/	
    DRV_PACKAGE_NAME=$(ls s3g-android-*-Elt-simple.tar.bz2 | sed 's/-simple.tar.bz2//g')
    #DRV_PACKAGE_NAME=$(ls $TEST_PROJECT_PATH | grep s3g-android-*-Elt)
    echo "Detected driver package name: $DRV_PACKAGE_NAME"      

    tar -xjf $DRV_PACKAGE_NAME-simple.tar.bz2

    if [ ! -d "$TEST_PROJECT_PATH/$DRV_PACKAGE_NAME" ]; then
        echo "Failed to detected driver package, now exit..."
        Exit_withCheck 2
    fi

    cd -
}


Check_Status()
{
    echo "Starting to check autotest status..."
    if [ -f "$AUTOTEST_PROJECT_CONF" ]; then
        PATCHSET_REVISION=$(sed -n '1p' $AUTOTEST_PROJECT_CONF)
        CONF_RESULT=$(sed -n '2p' $AUTOTEST_PROJECT_CONF)

        if [ "$PATCHSET_REVISION" = "$GERRIT_PATCHSET_REVISION" ] && [ $CONF_RESULT -ne 2 ]; then
            echo "Auto Test already done for current project, Now exit..."
            Exit_withCheck $CONF_RESULT
        fi
        rm -f $AUTOTEST_PROJECT_CONF
    fi  
}


Create_Package_Path()
{ 
    echo "Prepared package path: $TEST_PROJECT_PATH"
    if [ ! -d "$TEST_RESULT_PATH" ]; then
        echo "$TEST_RESULT_PATH is'nt exist, Creating it..."
        mkdir -p $TEST_RESULT_PATH
    fi

    if [ ! -d "$TEST_PROJECT_PATH" ]; then
        echo "$TEST_PROJECT_PATH is'nt exist, Creating it..."
        mkdir -p $TEST_PROJECT_PATH
    fi

    if [ -d "$TEST_PROJECT_PATH" ]; then
        echo "$TEST_PROJECT_PATH Prepared Successful."
    else
        echo "$TEST_PROJECT_PATH Prepared Failed"
    	Exit_withCheck 2
    fi
}

Write_ProjectInfo()
{  
    echo "Started to write project info...."
    
    echo "Project Information:  "  >   $AUTOTEST_RESULT_LOG   
    echo "Project Name   : $GERRIT_PROJECT"  >>  $AUTOTEST_RESULT_LOG
    echo "Project Owner  : $GERRIT_CHANGE_OWNER_EMAIL"  >>  $AUTOTEST_RESULT_LOG
    
    echo "Change Number  : $GERRIT_CHANGE_NUMBER "  >>  $AUTOTEST_RESULT_LOG
    echo "Change URL     : $GERRIT_CHANGE_URL"  >>  $AUTOTEST_RESULT_LOG
    echo "Change ID      : $GERRIT_CHANGE_ID"  >>  $AUTOTEST_RESULT_LOG
    echo "Change Subject : $GERRIT_CHANGE_SUBJECT"  >>  $AUTOTEST_RESULT_LOG
    echo "Change Email   : $GERRIT_EVENT_ACCOUNT_EMAIL"  >>  $AUTOTEST_RESULT_LOG
    echo "Uploader Email : $GERRIT_PATCHSET_UPLOADER_EMAIL"  >>  $AUTOTEST_RESULT_LOG
    echo "Change Name    : $GERRIT_EVENT_ACCOUNT_NAME"  >>  $AUTOTEST_RESULT_LOG
    echo "Patchset Numb  : $GERRIT_PATCHSET_NUMBER"  >>  $AUTOTEST_RESULT_LOG
    echo "Patchset ID    : $GERRIT_PATCHSET_REVISION" >>  $AUTOTEST_RESULT_LOG
	echo "Refspec Info   : $GERRIT_REFSPEC"  >>  $AUTOTEST_RESULT_LOG
}

Write_Build_Result()
{ 
    if [ ! -f "$AUTOTEST_RESULT_LOG" ]; then
        Write_ProjectInfo
        echo " " >> $AUTOTEST_RESULT_LOG
        echo "AutoTest Result:  " >> $AUTOTEST_RESULT_LOG
    fi

	if [ $AUTO_TEST_RET -eq 0 ]; then
        echo "${JOB_NAME##*/}:  Success." >> $AUTOTEST_RESULT_LOG
    else
        echo "${JOB_NAME##*/}:  Failed.!!!. Please Check...."  >> $AUTOTEST_RESULT_LOG
    fi   
}

# ----------------------------------------------

echo " "
echo "Autobuild jobs starting..."
echo "Job Name: ${JOB_NAME##*/} "
echo "WorkSpace: $WORKSPACE "
echo "Change Number  : $GERRIT_CHANGE_NUMBER "
echo "Patchset Numb  : $GERRIT_PATCHSET_NUMBER" 
echo "Refspec Info   : $GERRIT_REFSPEC" 
echo "Remote Pacage  : $REMOTE_DRV_PACK_PATH"
echo "AutoTest Path  : $TEST_PROJECT_PATH"
echo "AutoTest Script: $AUTOTEST_SCRIPT"
echo "Target DevID   : $TARGET_DEV_ID"
echo " "

AUTO_TEST_RET=2

Check_Status
Create_Package_Path
Get_Drv_Package

echo " "
echo "--------------------------------------------------------------"
echo "Starting to run auto test scripts for driver package..."
$AUOTTEST_ENV_PATH/$AUTOTEST_SCRIPT  $TEST_PROJECT_PATH/$DRV_PACKAGE_NAME  $TARGET_DEV_ID  $AUOTTEST_ENV_PATH
AUTO_TEST_RET=$?
echo "Auto Test Result is: $AUTO_TEST_RET"
echo "--------------------------------------------------------------"
echo " "

Write_Build_Result

#rm -rf $TEST_PROJECT_PATH/$DRV_PACKAGE_NAME
#rm -rf $TEST_PROJECT_PATH/$DRV_PACKAGE_NAME-simple.tar.bz2

Exit_withCheck $AUTO_TEST_RET
# ----------------------------------------------

