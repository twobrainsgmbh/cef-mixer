@echo off
setlocal

echo Welcome to the Chrome-bin copy script.
echo This script copies files from a Chrome-bin version subfolder to destination directories.
echo Example Chrome-bin version subfolder: F:\projects\cadability\cef-mixer\GoogleChromeCanaryDev\App\Chrome-bin\123.0.6262.5
echo.

REM Prompt the user to enter the path to the Chrome-bin version subfolder
set /p "chromePath=Enter the path to the Chrome-bin version subfolder: "

REM Construct absolute path if a relative path is provided
if not "%chromePath:~1,1%"==":" (
    set "chromePath=%cd%\%chromePath%"
)

REM Check if the provided path exists
if not exist "%chromePath%" (
    echo The provided path does not exist.
    exit /b 1
)

REM Construct destination paths
set "releaseDest=bin\x64-Release\src\Release"
set "debugDest=bin\x64-Debug\src\Debug"

REM Create destination directories if they do not exist
if not exist "%releaseDest%\" mkdir "%releaseDest%"
if not exist "%debugDest%\" mkdir "%debugDest%"

REM Copy files recursively without overwriting
xcopy /s /e /y "%chromePath%\*" "%releaseDest%\"
xcopy /s /e /y "%chromePath%\*" "%debugDest%\"

echo Files copied successfully.

:end
