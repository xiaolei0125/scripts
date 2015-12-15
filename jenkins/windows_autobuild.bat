;;@echo off
setlocal enableextensions

call :Print_Autobuild_Info
call :Create_Package_Path

echo.
set RET=0
echo Started to build driver...

set curren_build_name=Elite
set VS_path="%VS120COMNTOOLS%..\ide\devenv"
set solution_path=%WORKSPACE%\Elite\
set build_solution=Elite_v120.sln
set binary_path_src=%WORKSPACE%\Elite\bin\

set build_configuration="Windows 8 Release"
set build_project_configuration=
set need_files= opencl32.dll S3DDX9L_32.dll S3DDX10_32.dll S3ELDX9L_32.dll S3ELDX10_32.dll S3ELKMD_32.sys s3elldmoes_32.dll S3GUModeDX32.dll 
call :REBUILD

echo.
set VS_path="%VS90COMNTOOLS%..\ide\devenv"
set curren_build_name=EliteDX9
set build_solution=EliteDX9.sln
set build_configuration="WinXP x86 Release"
set need_files= S3EDX9_32.dll S3ELApp.cfg S3EMINI_32.sys 
call :REBUILD


call :Write_Build_Result
echo All building is finished with %RET%.
call :ExitWithCheck
exit /B %RET%


:REBUILD cb_
cd /d %solution_path%
echo Start to clean %curren_build_name% of %JOB_NAME% ...

copy /y %WORKSPACE%\Elite\Include\app_patch_elt.hpp  %WORKSPACE%\Elite\app_patch_elt_bak.hpp
if DEFINED build_project_configuration (
%VS_path% %build_solution% /clean %build_configuration% /project %build_project_configuration%  > %PROJECT_RESULT_PATH%\%curren_build_name%.log
) ELSE (
%VS_path% %build_solution% /clean %build_configuration%  > %PROJECT_RESULT_PATH%\%curren_build_name%.log
)

echo Start to rebuild %curren_build_name% of %JOB_NAME% ...

copy /y %WORKSPACE%\Elite\app_patch_elt_bak.hpp %WORKSPACE%\Elite\Include\app_patch_elt.hpp
if DEFINED build_project_configuration (
%VS_path% %build_solution% /rebuild %build_configuration% /project %build_project_configuration% >> %PROJECT_RESULT_PATH%\%curren_build_name%.log
) ELSE (
%VS_path% %build_solution% /rebuild %build_configuration%  >>  %PROJECT_RESULT_PATH%\%curren_build_name%.log
)
set CUR_RET=%errorlevel%

if %CUR_RET% EQU 0 (
    echo %curren_build_name% job autobuild success!
    echo %curren_build_name% job autobuild success!  >> %PROJECT_RESULT_PATH%\All_Build_Result.log
    FOR %%A IN (%need_files%) DO copy /y %binary_path_src%%%A  %PROJECT_RESULT_BIN_PATH%
    echo %curren_build_name% bin/package is released.
) else (
    echo %curren_build_name% autobuild failed!   >> %PROJECT_RESULT_PATH%\All_Build_Result.log
)

echo CUR_RET is %CUR_RET% 
echo RET is %RET%

if %RET% EQU 0 (
    set RET=%CUR_RET%  
    echo Update RET value with %CUR_RET%
)
GOTO :EOF


:ExitWithCheck cb_
    echo.
    echo Autobuild jobs exit with check...
    echo GERRIT_PATCHSET_REVISION is %GERRIT_PATCHSET_REVISION%

    set LINK=http://10.5.63.93:808/%GERRIT_CHANGE_NUMBER%/%JOB_NAME%/
    set MSG_SUCCESS="Build Successful: %LINK%"
    set MSG_FAILED="Build Failed: %LINK%"
   
    if %RET% EQU 0 (
        echo Exit with Success, refer to %LINK%
        ssh -p 29418 Jenkins_win@10.5.253.119 gerrit review -m  '%MSG_SUCCESS%'  %GERRIT_PATCHSET_REVISION%  --code-review +1
    ) else (
        echo Exit with Failed, refer to %LINK%
        ssh -p 29418 Jenkins_win@10.5.253.119 gerrit review -m  '%MSG_FAILED%'  %GERRIT_PATCHSET_REVISION%  --code-review -1
    )
GOTO :EOF

:Create_Package_Path cb_
    echo.
    echo Start to prepare building path...
    set BUILD_RESULT_PATH=D:\BuildResult\%GERRIT_CHANGE_NUMBER%
    set PROJECT_RESULT_PATH=%BUILD_RESULT_PATH%\%JOB_NAME%
    set PROJECT_RESULT_BIN_PATH=%PROJECT_RESULT_PATH%\bin

    if not exist %BUILD_RESULT_PATH% (
	md %BUILD_RESULT_PATH%
        echo %BUILD_RESULT_PATH% is'nt exist, Creating it...
	)

    if not exist %PROJECT_RESULT_PATH% (
	md %PROJECT_RESULT_PATH%
        echo %PROJECT_RESULT_PATH% is'nt exist, Creating it...
    ) else (
        rd /s /q  %PROJECT_RESULT_PATH%
        md %PROJECT_RESULT_PATH%
        echo Delete old %PROJECT_RESULT_PATH%, and re-creating it...
    )

    if not exist %PROJECT_RESULT_BIN_PATH% (
	md %PROJECT_RESULT_BIN_PATH%
        echo %PROJECT_RESULT_BIN_PATH% is'nt exist, Creating it...
	)

    if exist %PROJECT_RESULT_BIN_PATH% (
	md %PROJECT_RESULT_BIN_PATH%
        echo %PROJECT_RESULT_BIN_PATH% Prepared Successful.
    ) else (
        echo %PROJECT_RESULT_BIN_PATH% Prepared Failed.
        exit
        )
GOTO :EOF

:Write_ProjectInfo cb_
    echo Started to write project info....

    echo. > %PROJECT_INFO_FILE%
    echo Project Information:    >>   %PROJECT_INFO_FILE%
    echo Project Name   : %GERRIT_PROJECT%  >> %PROJECT_INFO_FILE%
    echo Project Job    : %JOB_NAME%  >> %PROJECT_INFO_FILE%
    echo Project Owner  : %GERRIT_CHANGE_OWNER_EMAIL%  >> %PROJECT_INFO_FILE%  
    echo Change Number  : %GERRIT_CHANGE_NUMBER%  >> %PROJECT_INFO_FILE% 
    echo Change URL     : %GERRIT_CHANGE_URL%  >> %PROJECT_INFO_FILE%
    echo Change ID      : %GERRIT_CHANGE_ID%  >> %PROJECT_INFO_FILE% 
    echo Change Subject : %GERRIT_CHANGE_SUBJECT%  >> %PROJECT_INFO_FILE%
    echo Change Email   : %GERRIT_PATCHSET_UPLOADER_EMAIL%  >> %PROJECT_INFO_FILE%
GOTO :EOF

:Write_Build_Result cb_
    set AUTOBUILD_RESULT_LOG=%BUILD_RESULT_PATH%/autobuild_result.log
    set PROJECT_INFO_FILE=%AUTOBUILD_RESULT_LOG%
    set EF_JOB_NAME="All"
    
    echo.
    echo Started to Write_Build_Result info....
    if not exist %AUTOBUILD_RESULT_LOG% (
        call :Write_ProjectInfo
        echo. >> %AUTOBUILD_RESULT_LOG%
        echo. >> %AUTOBUILD_RESULT_LOG%
        echo Autobuild Result:   >> %AUTOBUILD_RESULT_LOG%
    )

    if %RET% EQU 0 (
        echo %JOB_NAME%:  Success.  >> %AUTOBUILD_RESULT_LOG%
    ) else (
        echo %JOB_NAME%:  Failed.!!!. Please Check....  >> %AUTOBUILD_RESULT_LOG%
    )
GOTO :EOF

:Print_Autobuild_Info cb_
    echo.
    echo Autobuild jobs starting...
    echo Job Name: %JOB_NAME%,  Change Number: %GERRIT_CHANGE_NUMBER%
    echo WorkSpace: %WORKSPACE%
GOTO :EOF
