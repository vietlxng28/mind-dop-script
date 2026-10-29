@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "BACKEND_JAR=%SCRIPT_DIR%mind-dop-0.0.1-SNAPSHOT.jar"
set "FE_DIR=%SCRIPT_DIR%dist"
set "FE_PORT=3999"
set "BE_PORT=9999"

echo ==============================================
echo        KHỞI CHẠY HỆ THỐNG MIND DOP            
echo ==============================================

:: 1. Khởi chạy Backend
echo [1/3] Khởi chạy Backend [port %BE_PORT%]...
netstat -ano | findstr /R /C:":%BE_PORT% " >nul 2>&1
if not errorlevel 1 (
    echo   -^> Cổng %BE_PORT% đã có tiến trình chạy.
) else (
    if not exist "%BACKEND_JAR%" (
        echo   -^> Lỗi: Không tìm thấy tệp %BACKEND_JAR%!
        pause
        exit /b 1
    )
    start "Mind Dop Backend" /b javaw -jar "%BACKEND_JAR%" >> "%SCRIPT_DIR%backend.log" 2>&1
    echo   -^> Backend đã được khởi chạy ngầm [log: backend.log].
)

:: Chờ Backend sẵn sàng
echo   -^> Đang đợi Backend sẵn sàng...
set "be_ready=0"
for /L %%i in (1,1,30) do (
    if !be_ready! equ 0 (
        curl -s -f "http://localhost:%BE_PORT%/api/checkin/questions/active" >nul 2>&1
        if not errorlevel 1 (
            set "be_ready=1"
            echo   -^> Backend đã khởi động và sẵn sàng [port %BE_PORT%]!
        ) else (
            ping -n 2 127.0.0.1 >nul
        )
    )
)

if !be_ready! equ 0 (
    echo   -^> Backend khởi động chậm hoặc có lỗi, tiếp tục quy trình...
)

:: 2. Khởi chạy Frontend SPA
echo [2/3] Khởi chạy Frontend SPA [port %FE_PORT%]...
netstat -ano | findstr /R /C:":%FE_PORT% " >nul 2>&1
if not errorlevel 1 (
    echo   -^> Cổng %FE_PORT% đã có tiến trình chạy.
) else (
    if not exist "%FE_DIR%" (
        echo   -^> Lỗi: Không tìm thấy thư mục %FE_DIR%!
        pause
        exit /b 1
    )
    cd /d "%FE_DIR%"
    start "Mind Dop Frontend" /b python -m http.server %FE_PORT% >> "%SCRIPT_DIR%frontend.log" 2>&1
    cd /d "%SCRIPT_DIR%"
    echo   -^> Frontend đã được khởi chạy ngầm [log: frontend.log].
)

:: 3. Kiểm tra sẵn sàng và mở trình duyệt
echo [3/3] Kiểm tra kết nối và mở trình duyệt...
set "URL=http://localhost:%FE_PORT%"

for /L %%i in (1,1,10) do (
    curl -s -I "%URL%" >nul 2>&1
    if not errorlevel 1 goto :open_browser
    ping -n 2 127.0.0.1 >nul
)

:open_browser
echo   -^> Đang mở trình duyệt: %URL%
start "" "%URL%"

echo ==============================================
echo  Khởi chạy hoàn tất!
echo  - Giao diện Web:    %URL%
echo  - API Backend:      http://localhost:%BE_PORT%
echo  - Swagger Docs:     http://localhost:%BE_PORT%/swagger-ui.html
echo ==============================================
endlocal
