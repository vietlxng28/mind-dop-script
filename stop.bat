@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo Đang dừng các tiến trình Mind Dop...

set "FE_PORT=3999"
set "BE_PORT=9999"

:: Dừng tiến trình chiếm cổng FE_PORT
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /R /C:":%FE_PORT% "') do (
    if "%%a" neq "0" (
        echo   -^> Đang dừng tiến trình cổng %FE_PORT% [PID: %%a]...
        taskkill /f /pid %%a >nul 2>&1
    )
)

:: Dừng tiến trình chiếm cổng BE_PORT
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /R /C:":%BE_PORT% "') do (
    if "%%a" neq "0" (
        echo   -^> Đang dừng tiến trình cổng %BE_PORT% [PID: %%a]...
        taskkill /f /pid %%a >nul 2>&1
    )
)

echo Đã dừng toàn bộ dịch vụ FE và BE.
endlocal
