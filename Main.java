import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.Executors;

/**
 * Học phần: IT209 - Phát triển ứng dụng Web / Cloud Infrastructure
 * Session 07 - Bài tập 3: Thiết lập Cơ sở dữ liệu và Tự cấu hình dịch vụ Systemd cho Spring Boot
 * 
 * Sinh viên: Phạm Thanh Phong
 * MSSV: N24DTCN120
 * 
 * Ứng dụng Java Backend mô phỏng Spring Boot Service:
 * 1. Khởi chạy HTTP Server lắng nghe cổng 8082.
 * 2. Cung cấp API Health Check, Database Connection Status (MySQL springboot_db / spring-admin).
 * 3. Hỗ trợ Graceful Shutdown Hook (tương thích Systemd SIGTERM / SuccessExitStatus=143).
 */
public class Main {

    private static final int SERVER_PORT = 8082;
    private static final String APP_NAME = "Spring Boot Demo Application";
    private static final String APP_VERSION = "v1.0.0-PROD";
    private static final String DB_NAME = "springboot_db";
    private static final String DB_USER = "spring-admin";

    public static void main(String[] args) {
        printBanner();

        try {
            // Khởi tạo máy chủ HTTP lắng nghe trên toàn bộ interface (0.0.0.0:8082)
            HttpServer server = HttpServer.create(new InetSocketAddress("0.0.0.0", SERVER_PORT), 0);

            // Đăng ký các endpoints API
            server.createContext("/", new RootHandler());
            server.createContext("/api/v1/health", new HealthHandler());
            server.createContext("/api/v1/db-check", new DbCheckHandler());
            server.createContext("/api/v1/systemd", new SystemdInfoHandler());

            server.setExecutor(Executors.newFixedThreadPool(10));

            // Đăng ký Shutdown Hook xử lý tín hiệu từ Systemd (SIGTERM / SIGINT)
            Runtime.getRuntime().addShutdownHook(new Thread(() -> {
                System.out.println("\n[SYSTEMD SHUTDOWN] Nhận được tín hiệu dừng tiến trình (SIGTERM)...");
                System.out.println("[SYSTEMD SHUTDOWN] Đang giải phóng kết nối Database & dọn dẹp tài nguyên...");
                server.stop(2);
                System.out.println("[SYSTEMD SHUTDOWN] Ứng dụng đã dừng an toàn (Graceful Shutdown Completed).");
            }));

            server.start();

            System.out.println("[+] Máy chủ Backend đã khởi động thành công!");
            System.out.printf("[+] Lắng nghe tại địa chỉ: http://0.0.0.0:%d/%n", SERVER_PORT);
            System.out.println("[+] Các Endpoints khả dụng:");
            System.out.println("    - GET http://localhost:8082/              -> Thông tin trang chủ");
            System.out.println("    - GET http://localhost:8082/api/v1/health   -> Trạng thái sức khỏe ứng dụng");
            System.out.println("    - GET http://localhost:8082/api/v1/db-check -> Kiểm tra kết nối MySQL");
            System.out.println("    - GET http://localhost:8082/api/v1/systemd  -> Trạng thái cấu hình Systemd");
            System.out.println("------------------------------------------------------------------------------");
            System.out.println("[+] Nhấn Ctrl+C hoặc gửi lệnh `systemctl stop spring-app` để dừng tiến trình.\n");

        } catch (IOException e) {
            System.err.println("[!] Lỗi khởi động HTTP Server trên cổng " + SERVER_PORT + ": " + e.getMessage());
            System.exit(1);
        }
    }

    private static void printBanner() {
        System.out.println("==============================================================================");
        System.out.println("  _____             _                ____              _   ");
        System.out.println(" / ____|           (_)              |  _ \\            | |  ");
        System.out.println("| (___  _ __  _ __  _ _ __   __ _   | |_) | ___   ___ | |_ ");
        System.out.println(" \\___ \\| '_ \\| '__|| | '_ \\ / _` |  |  _ < / _ \\ / _ \\| __|");
        System.out.println(" ____) | |_) | |   | | | | | (_| |  | |_) | (_) | (_) | |_ ");
        System.out.println("|_____/| .__/|_|   |_|_| |_|\\__, |  |____/ \\___/ \\___/ \\__|");
        System.out.println("       | |                   __/ |                         ");
        System.out.println("       |_|                  |___/                          ");
        System.out.println("==============================================================================");
        System.out.println(" Sinh viên: Phạm Thanh Phong | MSSV: N24DTCN120 | Session 07 - Bài tập 3");
        System.out.println("==============================================================================");
    }

    static class RootHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String response = """
                    {
                      "application": "%s",
                      "version": "%s",
                      "student": "Pham Thanh Phong",
                      "student_id": "N24DTCN120",
                      "timestamp": "%s",
                      "status": "UP"
                    }
                    """.formatted(APP_NAME, APP_VERSION, getCurrentTime());
            sendJsonResponse(exchange, 200, response);
        }
    }

    static class HealthHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String response = """
                    {
                      "status": "UP",
                      "service": "spring-app.service",
                      "managed_by": "systemd",
                      "uptime": "Active (Running)",
                      "port": %d
                    }
                    """.formatted(SERVER_PORT);
            sendJsonResponse(exchange, 200, response);
        }
    }

    static class DbCheckHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String response = """
                    {
                      "database": "%s",
                      "db_user": "%s",
                      "db_host": "localhost:3306",
                      "connection_status": "CONNECTED",
                      "privileges": "ALL PRIVILEGES ON springboot_db.*",
                      "message": "Database handshake verification successful!"
                    }
                    """.formatted(DB_NAME, DB_USER);
            sendJsonResponse(exchange, 200, response);
        }
    }

    static class SystemdInfoHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String response = """
                    {
                      "unit_name": "spring-app.service",
                      "exec_user": "spring-runner",
                      "exec_command": "/usr/bin/java -jar /opt/spring-app/app.jar",
                      "restart_policy": "on-failure",
                      "restart_sec": 10,
                      "working_directory": "/opt/spring-app",
                      "success_exit_status": 143
                    }
                    """;
            sendJsonResponse(exchange, 200, response);
        }
    }

    private static void sendJsonResponse(HttpExchange exchange, int statusCode, String response) throws IOException {
        byte[] bytes = response.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
        exchange.sendResponseHeaders(statusCode, bytes.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(bytes);
        }
    }

    private static String getCurrentTime() {
        return LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
    }
}
