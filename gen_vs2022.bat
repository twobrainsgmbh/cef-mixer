@echo off

set CEF_ROOT=D:\projects\Trumpf\cadability\cef-mixer-chromium72\cef_binary_3.3599.1858.g285dbb1_windows64_minimal

set BASE_DIR=%~dp0
rem echo %BASE_DIR%

mkdir "%BASE_DIR%\build"

cd "%BASE_DIR%\build"

rem Visual Studio 2022
cmake -G "Visual Studio 17 2022" -A x64 "%BASE_DIR%"

cd %BASE_DIR%