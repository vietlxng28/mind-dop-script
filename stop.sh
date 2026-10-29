#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Đang dừng các tiến trình Mind Dop..."

# Dừng theo port
fuser -k 3999/tcp 2>/dev/null || true
fuser -k 9999/tcp 2>/dev/null || true

# Dừng systemd transient units nếu có
systemctl --user stop mind-dop-fe 2>/dev/null || true
systemctl --user stop mind-dop-be 2>/dev/null || true
systemctl --user reset-failed mind-dop-fe 2>/dev/null || true
systemctl --user reset-failed mind-dop-be 2>/dev/null || true

echo "Đã dừng toàn bộ dịch vụ FE và BE."
