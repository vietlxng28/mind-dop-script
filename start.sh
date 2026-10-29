#!/usr/bin/env python3
import os
import sys
import time
import subprocess
import shutil

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BACKEND_JAR = os.path.join(SCRIPT_DIR, "mind-dop-0.0.1-SNAPSHOT.jar")
FE_DIR = os.path.join(SCRIPT_DIR, "dist")
FE_PORT = 3999
BE_PORT = 9999

# Đảm bảo các đường dẫn PATH chuẩn (bao gồm SDKMAN Java và các binary hệ thống)
extra_paths = [
    os.path.expanduser("~/.sdkman/candidates/java/current/bin"),
    "/usr/local/bin",
    "/usr/bin",
    "/bin"
]
for p in extra_paths:
    if p not in os.environ.get("PATH", ""):
        os.environ["PATH"] = f"{p}:{os.environ.get('PATH', '')}"

print("==============================================")
print("       KHỞI CHẠY HỆ THỐNG MIND DOP            ")
print("==============================================")

# Hàm kiểm tra port đang bận
def is_port_in_use(port):
    res = subprocess.run(["lsof", "-i", f":{port}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return res.returncode == 0

# Tìm đường dẫn binary java
java_bin = shutil.which("java") or os.path.expanduser("~/.sdkman/candidates/java/current/bin/java")

# 1. Khởi chạy Backend
print(f"[1/3] Khởi chạy Backend (port {BE_PORT})...")
if is_port_in_use(BE_PORT):
    print(f"  -> Cổng {BE_PORT} đã có tiến trình chạy.")
else:
    if not os.path.isfile(BACKEND_JAR):
        print(f"  -> Lỗi: Không tìm thấy tệp {BACKEND_JAR}!")
        sys.exit(1)
    be_log = open(os.path.join(SCRIPT_DIR, "backend.log"), "a")
    p_be = subprocess.Popen(
        [java_bin, "-jar", BACKEND_JAR],
        cwd=SCRIPT_DIR,
        stdout=be_log,
        stderr=subprocess.STDOUT,
        start_new_session=True,
        env=os.environ
    )
    print(f"  -> Backend đã được khởi chạy ngầm (PID: {p_be.pid}, log: backend.log).")

# Chờ Backend khởi động và sẵn sàng nhận kết nối API
print("  -> Đang đợi Backend sẵn sàng...")
be_ready = False
be_health_url = f"http://localhost:{BE_PORT}/api/checkin/questions/active"

for _ in range(30):
    res = subprocess.run(["curl", "-s", be_health_url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if res.returncode == 0:
        be_ready = True
        print(f"  -> Backend đã khởi động và sẵn sàng (port {BE_PORT})!")
        break
    time.sleep(0.5)

if not be_ready:
    print("  -> Backend khởi động chậm hoặc có lỗi, tiếp tục quy trình...")

# 2. Khởi chạy Frontend SPA
print(f"[2/3] Khởi chạy Frontend SPA (port {FE_PORT})...")
if is_port_in_use(FE_PORT):
    print(f"  -> Cổng {FE_PORT} đã có tiến trình chạy.")
else:
    if not os.path.isdir(FE_DIR):
        print(f"  -> Lỗi: Không tìm thấy thư mục {FE_DIR}!")
        sys.exit(1)
    fe_log = open(os.path.join(SCRIPT_DIR, "frontend.log"), "a")
    p_fe = subprocess.Popen(
        [sys.executable, "-m", "http.server", str(FE_PORT), "--directory", FE_DIR],
        cwd=FE_DIR,
        stdout=fe_log,
        stderr=subprocess.STDOUT,
        start_new_session=True
    )
    print(f"  -> Frontend đã được khởi chạy ngầm (PID: {p_fe.pid}, log: frontend.log).")

# 3. Kiểm tra sẵn sàng và mở trình duyệt
print("[3/3] Kiểm tra kết nối và mở trình duyệt...")
url = f"http://localhost:{FE_PORT}"

for _ in range(15):
    res = subprocess.run(["curl", "-s", "-I", url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if res.returncode == 0:
        print("  -> Đã kết nối thành công tới Frontend!")
        break
    time.sleep(0.5)

print(f"  -> Đang mở trình duyệt: {url}")
browser_cmd = None
for b in ["xdg-open", "google-chrome", "sensible-browser"]:
    if shutil.which(b):
        browser_cmd = b
        break

if browser_cmd:
    subprocess.Popen([browser_cmd, url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)

print("==============================================")
print(" Khởi chạy hoàn tất!")
print(f" - Giao diện Web:    {url}")
print(f" - API Backend:      http://localhost:{BE_PORT}")
print(f" - Swagger Docs:     http://localhost:{BE_PORT}/swagger-ui.html")
print("==============================================")
