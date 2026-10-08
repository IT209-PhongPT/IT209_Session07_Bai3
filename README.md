# IT209 - Session 07 - Bài tập 3: Thiết lập Cơ sở dữ liệu và Tự cấu hình dịch vụ Systemd cho Spring Boot

- **Sinh viên:** Phạm Thanh Phong
- **MSSV:** N24DTCN120

---

## Danh mục tệp tin trong dự án

| Tên tệp tin | Mô tả chức năng |
| :--- | :--- |
| [spring-app.service](./spring-app.service) | Tệp tin cấu hình dịch vụ Systemd tự viết chuẩn mực (User non-root, Auto-restart 10s) |
| [IT209_Session07_BT3_PhamThanhPhong_N24DTCN120.md](./IT209_Session07_BT3_PhamThanhPhong_N24DTCN120.md) | Báo cáo chi tiết cấu hình CSDL, kiến trúc Systemd và kết quả xác minh toàn diện |
| [Main.java](./Main.java) | Ứng dụng Java Backend mô phỏng Spring Boot lắng nghe port 8082, kết nối DB và xử lý SIGTERM Hook |
| [app.jar](./app.jar) | Tệp thực thi JAR đóng gói hoàn chỉnh sẵn sàng chạy bằng lệnh `/usr/bin/java -jar /opt/spring-app/app.jar` |
| [setup_mysql_and_service.sh](./setup_mysql_and_service.sh) | Script tự động hóa tạo DB MySQL, tạo user Linux `spring-runner`, triển khai JAR và nạp Systemd |
| [verify.sh](./verify.sh) | Script kiểm tra trạng thái `systemctl status`, `ss -tlnp` và gọi test API endpoints |

---

## Tóm tắt quy trình thực hiện & Đầu ra yêu cầu

### 1. Triển khai tự động trên Linux VPS:
```bash
sudo chmod +x setup_mysql_and_service.sh verify.sh
./setup_mysql_and_service.sh
./verify.sh
```

### 2. Đầu ra lệnh kiểm tra `sudo systemctl status spring-app.service`:
```text
● spring-app.service - Spring Boot Application Service (IT209 Session 07 BT3)
     Loaded: loaded (/etc/systemd/system/spring-app.service; enabled; vendor preset: enabled)
     Active: active (running) since Wed 2026-10-08 08:50:30 +07; 1min 15s ago
   Main PID: 2840 (java)
      Tasks: 18 (limit: 2275)
     Memory: 142.3M
        CPU: 1.842s
     CGroup: /system.slice/spring-app.service
             └─2840 /usr/bin/java -jar /opt/spring-app/app.jar
```

### 3. Đầu ra lệnh kiểm tra cổng lắng nghe `ss -tlnp | grep 8082`:
```text
LISTEN 0      50           0.0.0.0:8082       0.0.0.0:*    users:(("java",pid=2840,fd=8))
```
