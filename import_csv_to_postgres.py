import pandas as pd
from sqlalchemy import create_engine
import argparse

def import_csv_to_postgres(csv_file_path, db_url, table_name):
    """
    Đọc file CSV và thay thế nội dung bảng trong PostgreSQL.
    """
    print(f"Đang đọc file CSV: {csv_file_path}")
    # Đọc file CSV bằng pandas
    df = pd.read_csv(csv_file_path)
    
    print("Đang kết nối đến cơ sở dữ liệu PostgreSQL...")
    # Tạo kết nối SQLAlchemy engine
    engine = create_engine(db_url)
    
    print(f"Đang thay thế nội dung bảng '{table_name}'...")
    # Thay thế bảng trong DB
    # if_exists='replace' sẽ xoá bảng cũ (drop table) và tạo bảng mới với dữ liệu từ CSV.
    # index=False để không lưu cột index của DataFrame vào Database.
    df.to_sql(table_name, engine, if_exists='replace', index=False)
    
    print("Hoàn tất việc ghi dữ liệu vào database!")

if __name__ == "__main__":
    # Ví dụ cách chạy script:
    # python import_csv_to_postgres.py --csv data.csv --url "postgresql://username:password@localhost:5432/database_name" --table my_table
    parser = argparse.ArgumentParser(description="Import dữ liệu từ file CSV vào PostgreSQL, ghi đè bảng hiện tại.")
    parser.add_argument("--csv", required=True, help="Đường dẫn tới file CSV đầu vào")
    parser.add_argument("--url", required=True, help="Chuỗi kết nối PostgreSQL (VD: postgresql://username:password@localhost:5432/db_name)")
    parser.add_argument("--table", required=True, help="Tên bảng cần thay thế dữ liệu")
    
    args = parser.parse_args()
    
    import_csv_to_postgres(args.csv, args.url, args.table)
