@if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off
@echo on

:: ----------------------
:: KUDU Deployment Script
:: Version: 1.0.17
:: ----------------------

:: Prerequisites
:: -------------

:: Verify node.js installed
where node 2>nul >nul
IF %ERRORLEVEL% NEQ 0 (
  echo Missing node.js executable, please install node.js, if already installed make sure it can be reached from current environment.
  goto error
)

:: Setup
:: -----

setlocal enabledelayedexpansion

SET ARTIFACTS=%~dp0%..\artifacts

IF NOT DEFINED DEPLOYMENT_SOURCE (
  SET DEPLOYMENT_SOURCE=%~dp0%.
)

IF NOT DEFINED DEPLOYMENT_TARGET (
  SET DEPLOYMENT_TARGET=%ARTIFACTS%\wwwroot
)

IF NOT DEFINED NEXT_MANIFEST_PATH (
  SET NEXT_MANIFEST_PATH=%ARTIFACTS%\manifest

  IF NOT DEFINED PREVIOUS_MANIFEST_PATH (
    SET PREVIOUS_MANIFEST_PATH=%ARTIFACTS%\manifest
  )
)

IF NOT DEFINED KUDU_SYNC_CMD (
  :: Install kudu sync
  echo Installing Kudu Sync
  call npm install kudusync -g --silent
  IF !ERRORLEVEL! NEQ 0 goto error

  :: Locally just running "kuduSync" would also work
  SET KUDU_SYNC_CMD=%appdata%\npm\kuduSync.cmd
)

  SET DEPLOYMENT_TEMP=%temp%\deployconfig
  SET CLEAN_LOCAL_DEPLOYMENT_TEMP=true


IF DEFINED CLEAN_LOCAL_DEPLOYMENT_TEMP (
  IF EXIST "%DEPLOYMENT_TEMP%" rd /s /q "%DEPLOYMENT_TEMP%"
  mkdir "%DEPLOYMENT_TEMP%"
)

SET MSBUILD_PATH=%MSBUILD_15_DIR%\MSBuild.exe

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Deployment
:: ----------

echo Handling ASP.NET Core Web Application deployment.
echo %MSBUILD_15_DIR%
echo deployment source
:: 1. Restore nuget packages
call :ExecuteCmd nuget restore "%DEPLOYMENT_SOURCE%\Source\Microsoft.Teams.Apps.QBot.sln"

call :ExecuteCmd dotnet restore "%DEPLOYMENT_SOURCE%\Source\Microsoft.Teams.Apps.QBot.sln"
IF !ERRORLEVEL! NEQ 0 goto error
echo building project
:: 2. Build and publish
echo building Data project
call :ExecuteCmd "%MSBUILD_PATH%" "%DEPLOYMENT_SOURCE%\Source\Microsoft.Teams.Apps.QBot.Data\Microsoft.Teams.Apps.QBot.Data.csproj" /verbosity:m /t:Build /t:pipelinePreDeployCopyAllFilesToOneFolder /p:_PackageTempDir="%DEPLOYMENT_TEMP%";Configuration=Release;UseSharedCompilation=false /p:SolutionDir="%DEPLOYMENT_SOURCE%\Source\\"
echo done building Data project

echo building questions project
call :ExecuteCmd dotnet publish "%DEPLOYMENT_SOURCE%\Source\QuestionsTabApp\QuestionsTabApp.csproj" --output "%DEPLOYMENT_TEMP%" --configuration Release
IF !ERRORLEVEL! NEQ 0 goto error
echo done building questions project

:: 3. KuduSync
echo starting publish
echo Temp %DEPLOYMENT_TEMP%
echo Target %DEPLOYMENT_TARGET%
echo manifest path %NEXT_MANIFEST_PATH%

call :ExecuteCmd "%KUDU_SYNC_CMD%" -v 50 -f "%DEPLOYMENT_SOURCE%\Source\QuestionsTabApp\wwwroot" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.hg;.deployment;deploy.cmd"
IF !ERRORLEVEL! NEQ 0 goto error

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
goto end

:: Execute command routine that will echo out when error
:ExecuteCmd
setlocal
set _CMD_=%*
call %_CMD_%
if "%ERRORLEVEL%" NEQ "0" echo Failed exitCode=%ERRORLEVEL%, command=%_CMD_%
exit /b %ERRORLEVEL%

:error
endlocal
echo An error has occurred during web site deployment.
call :exitSetErrorLevel
call :exitFromFunction 2>nul

:exitSetErrorLevel
exit /b 1

:exitFromFunction
()

:end
endlocal
echo Finished successfully.
