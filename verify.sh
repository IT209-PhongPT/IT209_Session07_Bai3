#!/usr/bin/env bash
# ==============================================================================
# Script kiểm tra và xác thực trạng thái Systemd Service và Socket cổng 8082
# Học phần: IT209 - Session 07 - BT3
# Sinh viên: Phạm Thanh Phong - MSSV: N24DTCN120
# ==============================================================================

SERVICE_NAME="spring-app.service"
PORT=8082

echo "=============================================================================="
echo " KIỂM ĐỊNH DỊCH VỤ SYSTEMD & SOCKET CỔNG ${PORT} (IT209 - SESSION 07 - BT3)  "
echo "=============================================================================="

# 1. Kiểm tra trạng thái dịch vụ Systemd
echo ""
echo "[1] ĐẦU RA LỆNH: sudo systemctl status ${SERVICE_NAME}"
echo "------------------------------------------------------------------------------"
sudo systemctl status "${SERVICE_NAME}" --no-pager || true
echo "------------------------------------------------------------------------------"

# 2. Kiểm tra cổng lắng nghe qua lệnh ss
echo ""
echo "[2] ĐẦU RA LỆNH: ss -tlnp | grep ${PORT}"
echo "------------------------------------------------------------------------------"
sudo ss -tlnp | grep "${PORT}" || echo "Cảnh báo: Không tìm thấy tiến trình lắng nghe cổng ${PORT}."
echo "------------------------------------------------------------------------------"

# 3. Kiểm tra người dùng thực thi (Mong muốn: user spring-runner, không phải root)
echo ""
echo "[3] KIỂM TRA TIẾN TRÌNH VÀ USER THỰC THI (ps aux):"
ps aux | grep "[j]ava.*app.jar" || echo "Không tìm thấy tiến trình Java."

# 4. Kiểm thử gọi API Endpoints
echo ""
echo "[4] KIỂM THỬ TRUY CẬP HTTP ENDPOINT (curl http://localhost:${PORT}/api/v1/health):"
if command -v curl &>/dev/null; then
    curl -s http://localhost:${PORT}/api/v1/health | grep -E "status|service|uptime" || true
    echo ""
    echo "[+] Kiểm tra kết nối MySQL qua API:"
    curl -s http://localhost:${PORT}/api/v1/db-check || true
fi

# 5. Kiểm tra kết nối MySQL trực tiếp với user spring-admin
echo ""
echo ""
echo "[5] KIỂM TRA ĐĂNG NHẬP MYSQL BẰNG USER spring-admin:"
mysql -u spring-admin -pSpringSecure@123 -e "SHOW DATABASES LIKE 'springboot_db'; SELECT CURRENT_USER(), DATABASE();" 2>/dev/null || echo "[!] Cần cài đặt mysql-client để chạy lệnh kiểm tra trực tiếp."

echo ""
echo "=============================================================================="
echo " HOÀN TẤT KIỂM ĐỊNH DỊCH VỤ SPRING BOOT SYSTEMD!"
echo "=============================================================================="
