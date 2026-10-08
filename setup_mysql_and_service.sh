#!/usr/bin/env bash
# ==============================================================================
# Học phần: IT209 - Phát triển ứng dụng Web / Cloud Infrastructure
# Session 07 - Bài tập 3: Thiết lập Cơ sở dữ liệu và Tự cấu hình dịch vụ Systemd cho Spring Boot
# Sinh viên: Phạm Thanh Phong - MSSV: N24DTCN120
#
# Mục đích: Thiết lập CSDL MySQL, tạo tài khoản Linux giới hạn spring-runner và cấu hình dịch vụ Systemd
# ==============================================================================

set -euo pipefail

echo "=============================================================================="
echo " KHỞI TẠO CƠ SỞ DỮ LIỆU MYSQL & DỊCH VỤ SYSTEMD (IT209 - SESSION 07 - BT3)    "
echo " Sinh viên: Phạm Thanh Phong | MSSV: N24DTCN120                                "
echo "=============================================================================="

# ------------------------------------------------------------------------------
# BƯỚC 1: KHỞI TẠO CƠ SỞ DỮ LIỆU MYSQL & CẤU HÌNH PHÂN QUYỀN USER
# ------------------------------------------------------------------------------
echo ""
echo "[+] [1/4] Đang khởi tạo Database và User trên MySQL Server..."

# Đảm bảo dịch vụ MySQL đang chạy
sudo systemctl start mysql 2>/dev/null || sudo systemctl start mysqld 2>/dev/null || true

sudo mysql -u root <<EOF
-- Tạo database springboot_db nếu chưa tồn tại
CREATE DATABASE IF NOT EXISTS springboot_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Tạo user spring-admin với mật khẩu SpringSecure@123
CREATE USER IF NOT EXISTS 'spring-admin'@'localhost' IDENTIFIED BY 'SpringSecure@123';
ALTER USER 'spring-admin'@'localhost' IDENTIFIED BY 'SpringSecure@123';

-- Cấp toàn quyền thao tác trên database springboot_db
GRANT ALL PRIVILEGES ON springboot_db.* TO 'spring-admin'@'localhost';

-- Nạp lại bảng phân quyền
FLUSH PRIVILEGES;
EOF

echo "[OK] Đã tạo database 'springboot_db' và cấp toàn quyền cho user 'spring-admin'."

# ------------------------------------------------------------------------------
# BƯỚC 2: KHỞI TẠO TÀI KHOẢN HỆ THỐNG LINUX (SYSTEM USER: spring-runner)
# ------------------------------------------------------------------------------
echo ""
echo "[+] [2/4] Đang tạo tài khoản hệ thống không có shell login 'spring-runner'..."

if id "spring-runner" &>/dev/null; then
    echo "[!] Tài khoản 'spring-runner' đã tồn tại."
else
    sudo useradd --system \
                 --shell /usr/sbin/nologin \
                 --home-dir /opt/spring-app \
                 --no-create-home \
                 --user-group \
                 spring-runner
    echo "[OK] Đã tạo system user 'spring-runner' (shell: /usr/sbin/nologin)."
fi

# ------------------------------------------------------------------------------
# BƯỚC 3: TRIỂN KHAI ỨNG DỤNG VÀO /opt/spring-app/
# ------------------------------------------------------------------------------
echo ""
echo "[+] [3/4] Đang thiết lập thư mục ứng dụng /opt/spring-app/..."

sudo mkdir -p /opt/spring-app

# Copy tệp app.jar vào /opt/spring-app/
if [ -f "app.jar" ]; then
    sudo cp app.jar /opt/spring-app/app.jar
else
    echo "[!] Cảnh báo: Tệp app.jar chưa có trong thư mục hiện tại. Đang tạo tệp app.jar mẫu..."
    javac Main.java && jar cfe app.jar Main *.class
    sudo cp app.jar /opt/spring-app/app.jar
fi

# Phân quyền cho user spring-runner
sudo chown -R spring-runner:spring-runner /opt/spring-app
sudo chmod 750 /opt/spring-app
sudo chmod 640 /opt/spring-app/app.jar

echo "[OK] Đã phân quyền /opt/spring-app cho user 'spring-runner'."

# ------------------------------------------------------------------------------
# BƯỚC 4: CÀI ĐẶT & KÍCH HOẠT DỊCH VỤ SYSTEMD
# ------------------------------------------------------------------------------
echo ""
echo "[+] [4/4] Đang cài đặt tệp dịch vụ /etc/systemd/system/spring-app.service..."

sudo cp spring-app.service /etc/systemd/system/spring-app.service
sudo chmod 644 /etc/systemd/system/spring-app.service

# Nạp lại cấu hình Systemd Daemon
echo "[+] Thực hiện daemon-reload..."
sudo systemctl daemon-reload

# Kích hoạt khởi động cùng hệ thống và chạy dịch vụ ngay lập tức
echo "[+] Kích hoạt và khởi chạy dịch vụ spring-app.service..."
sudo systemctl enable spring-app.service
sudo systemctl restart spring-app.service

echo ""
echo "=============================================================================="
echo " TRIỂN KHAI VÀ KHỞI CHẠY DỊCH VỤ THÀNH CÔNG!"
echo "=============================================================================="
