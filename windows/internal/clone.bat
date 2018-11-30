@echo off

:: The conda and wheels jobs are seperated on Windows, so we don't need to clone again.
if exist "%NIGHTLIES_PYTORCH_ROOT%" (
    xcopy /E /Y /Q "%NIGHTLIES_PYTORCH_ROOT%" pytorch\
    cd pytorch
    goto submodule
)

git clone https://github.com/%PYTORCH_REPO%/pytorch

cd pytorch

IF "%PYTORCH_BRANCH%" == "latest" goto latest_start else goto latest_end

:latest_start

if "%NIGHTLIES_DATE%" == "" goto date_start else goto date_end

:date_start

set "DATE_CMD=Get-Date ([System.TimeZoneInfo]::ConvertTimeFromUtc((Get-Date).ToUniversalTime(), [System.TimeZoneInfo]::FindSystemTimeZoneById('Pacific Standard Time'))) -f 'yyyy_MM_dd'"
set "DATE_COMPACT_CMD=Get-Date ([System.TimeZoneInfo]::ConvertTimeFromUtc((Get-Date).ToUniversalTime(), [System.TimeZoneInfo]::FindSystemTimeZoneById('Pacific Standard Time'))) -f 'yyyyMMdd'"

FOR /F "delims=" %%i IN ('powershell -c "%DATE_CMD%"') DO set NIGHTLIES_DATE=%%i
FOR /F "delims=" %%i IN ('powershell -c "%DATE_COMPACT_CMD%"') DO set NIGHTLIES_DATE_COMPACT=%%i

:date_end

if "%NIGHTLIES_DATE_COMPACT%" == "" set NIGHTLIES_DATE_COMPACT=%NIGHTLIES_DATE:~0,4%%NIGHTLIES_DATE:~5,2%%NIGHTLIES_DATE:~8,2%

:: Switch to the latest commit by 11:59 yesterday
echo PYTORCH_BRANCH is set to latest so I will find the last commit
echo before 0:00 midnight on %NIGHTLIES_DATE%
set git_date=%NIGHTLIES_DATE:_=-%
FOR /F "delims=" %%i IN ('git log --before %git_date% -n 1 "--pretty=%%H"') DO set last_commit=%%i
echo Setting PYTORCH_BRANCH to %last_commit% since that was the last
echo commit before %NIGHTLIES_DATE%
set PYTORCH_BRANCH=%last_commit%

:latest_end

IF "%PYTORCH_BRANCH%" == "" (
    set PYTORCH_BRANCH=v%PYTORCH_BUILD_VERSION%
)
git checkout tags/%PYTORCH_BRANCH%
IF ERRORLEVEL 1 git checkout %PYTORCH_BRANCH%

:submodule

git submodule update --init --recursive
IF ERRORLEVEL 1 exit /b 1
