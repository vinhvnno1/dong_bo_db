# Database Synchronization & Tool Scripts

Kho chứa này bao gồm các file SQL để khởi tạo schema cho cơ sở dữ liệu dự án (TopAICollection) và các script Python giúp đồng bộ, cập nhật, và kiểm tra dữ liệu tự động cho các bảng dữ liệu liên quan đến công cụ AI.

## 1. Các Script Python (Công cụ Xử lý Dữ liệu)

Các script Python được viết với thư viện `pandas` và `SQLAlchemy`, dùng để tự động hóa quá trình đồng bộ và trích xuất dữ liệu.

* **`dongbo.py`**: Script đồng bộ dữ liệu cột `name` từ bảng `Tool_en` (database A: `mydb`) sang bảng `Tool` (database B: `new_db`), dựa vào ID mapping.
  ```powershell
  # Chạy script để xem trước quá trình đồng bộ:
  python dongbo.py --dry-run
  
  # Chạy đồng bộ thực tế:
  python dongbo.py
  ```

* **`update_tool_translation.py`**: Script đọc dữ liệu từ file CSV (`mapper100-160_replaced_desc.csv`) và cập nhật cột `shortDesc` trong bảng `ToolTranslation` của PostgreSQL (áp dụng cho ngôn ngữ `en`).
  ```powershell
  python update_tool_translation.py
  ```

* **`testdb.py`**: Công cụ CLI tương tác cho phép tìm kiếm trực tiếp trong database để kiểm tra nhanh `shortDesc` của Tool trong `ToolTranslation`.
  - Hỗ trợ **Chế độ 1**: Tìm kiếm theo Tên Tool.
  - Hỗ trợ **Chế độ 2**: Tìm kiếm nội dung bên trong `shortDesc`.
  ```powershell
  python testdb.py
  ```

* **`import_csv_to_postgres.py`**: *(Lưu ý khi sử dụng)* Script dùng pandas để nhập dữ liệu CSV ghi đè (replace) toàn bộ bảng trong PostgreSQL. Rất hữu ích khi cần tạo mới lại hoàn toàn một bảng từ file dữ liệu có sẵn.

## 2. File SQL (Khởi tạo Schema)

Hai file SQL để dựng database mẫu cho trang chi tiết công cụ AI.

- `topaicollection_schema.sql` — Dành cho PostgreSQL (khuyến nghị)
- `topaicollection_schema_mysql.sql` — Dành cho MySQL 8.0+

### Cách khởi tạo Database bằng lệnh (CLI)

**PostgreSQL:**
```bash
psql -U postgres -d your_db -f topaicollection_schema.sql
```

**MySQL:**
```bash
mysql -u root -p your_db < topaicollection_schema_mysql.sql
```
*(Lưu ý: Các script này sử dụng `DROP TABLE IF EXISTS` ở đầu file, nên bạn có thể chạy lại nhiều lần để reset dữ liệu).*

## Cấu hình môi trường Python (Dành cho nhà phát triển)

Nếu bạn chạy source code này trên máy mới, hãy đảm bảo khởi tạo môi trường ảo `.venv` và cài đặt các thư viện cần thiết:
```powershell
# Tạo môi trường ảo
python -m venv .venv

# Kích hoạt môi trường (Windows PowerShell)
.\.venv\Scripts\Activate.ps1

# Cài đặt các thư viện
pip install pandas sqlalchemy psycopg2-binary
```
