"""
=============================================================
  Script: update_tool_translation.py
  Mục đích: Đọc file CSV, lấy cột shortDesc và cập nhật vào
            bảng ToolTranslation trong PostgreSQL.
  Công nghệ: SQLAlchemy (Core) + pandas
  Tác giả: Auto-generated
  Ngày tạo: 2026-05-15
=============================================================

Cách chạy:
  py update_tool_translation.py

Hoặc tuỳ chỉnh tham số:
  py update_tool_translation.py --csv "path/to/file.csv" --locale en
=============================================================
"""

import sys
import io
import argparse
import logging
from datetime import datetime

import pandas as pd
from sqlalchemy import create_engine, text

# ── Cấu hình mặc định ──────────────────────────────────────
# Chuỗi kết nối PostgreSQL (thay đổi nếu cần)
DATABASE_URL = "postgresql://postgres:8989@localhost:5432/new_db"

# Đường dẫn file CSV mặc định
DEFAULT_CSV_PATH = "mapper100-160_replaced_desc.csv"

# Locale cần cập nhật (mặc định là "en")
DEFAULT_LOCALE = "en"

# ── Fix encoding cho Windows console ────────────────────────
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# ── Cấu hình logging ───────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-7s | %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)


# =============================================================
#  HÀM CHÍNH
# =============================================================

def read_csv_short_desc(csv_path: str) -> pd.DataFrame:
    """
    Đọc file CSV và trích xuất 2 cột cần thiết:
      - id       : UUID của tool (dùng làm khoá để map với toolId)
      - shortDesc: mô tả ngắn mới cần cập nhật

    Returns:
        DataFrame chứa các dòng có shortDesc hợp lệ (không rỗng).
    """
    logger.info(f"Dang doc file CSV: {csv_path}")
    df = pd.read_csv(csv_path, usecols=["id", "shortDesc"])

    # Loại bỏ các dòng không có shortDesc
    df = df.dropna(subset=["shortDesc"])

    # Loại bỏ khoảng trắng thừa
    df["shortDesc"] = df["shortDesc"].str.strip()

    # Loại bỏ dòng có shortDesc rỗng sau khi strip
    df = df[df["shortDesc"] != ""]

    logger.info(f"Tim thay {len(df)} dong co shortDesc hop le trong CSV.")
    return df


def update_tool_translations(
    engine,
    df: pd.DataFrame,
    locale: str,
) -> dict:
    """
    Cập nhật cột shortDesc trong bảng ToolTranslation cho locale chỉ định.

    Logic:
      - Với mỗi dòng trong CSV, tìm bản ghi ToolTranslation có
        toolId = csv.id AND locale = locale
      - Nếu tìm thấy → UPDATE shortDesc
      - Nếu không tìm thấy → bỏ qua và ghi log cảnh báo

    Args:
        engine : SQLAlchemy engine đã kết nối DB.
        df     : DataFrame gồm cột 'id' (toolId) và 'shortDesc'.
        locale : Mã ngôn ngữ cần cập nhật (vd: "en", "vi").

    Returns:
        Dict chứa thống kê: updated, skipped, errors.
    """
    # Câu lệnh UPDATE với tham số truyền vào
    update_sql = text("""
        UPDATE "ToolTranslation"
        SET "shortDesc" = :new_desc,
            "updatedAt" = :now
        WHERE "toolId" = :tool_id
          AND "locale"  = :locale
    """)

    stats = {"updated": 0, "skipped": 0, "errors": 0}
    now = datetime.utcnow()

    # Sử dụng transaction để đảm bảo tính toàn vẹn dữ liệu
    with engine.begin() as conn:
        for idx, row in df.iterrows():
            tool_id = row["id"]
            new_desc = row["shortDesc"]

            try:
                result = conn.execute(
                    update_sql,
                    {
                        "new_desc": new_desc,
                        "now": now,
                        "tool_id": tool_id,
                        "locale": locale,
                    },
                )

                if result.rowcount > 0:
                    stats["updated"] += 1
                    logger.debug(f"  [OK] toolId={tool_id}")
                else:
                    # Không tìm thấy bản ghi tương ứng
                    stats["skipped"] += 1
                    logger.warning(
                        f"  [SKIP] Khong tim thay ToolTranslation "
                        f"voi toolId={tool_id}, locale={locale}"
                    )

            except Exception as e:
                stats["errors"] += 1
                logger.error(f"  [ERROR] toolId={tool_id}: {e}")

    return stats


def print_summary(stats: dict, locale: str) -> None:
    """In báo cáo tổng kết sau khi cập nhật."""
    logger.info("=" * 55)
    logger.info("  BAO CAO KET QUA CAP NHAT")
    logger.info("=" * 55)
    logger.info(f"  Locale           : {locale}")
    logger.info(f"  So dong cap nhat : {stats['updated']}")
    logger.info(f"  So dong bo qua   : {stats['skipped']}")
    logger.info(f"  So loi           : {stats['errors']}")
    logger.info("=" * 55)

    if stats["errors"] > 0:
        logger.warning("Co loi xay ra! Kiem tra log phia tren de biet chi tiet.")
    else:
        logger.info("Hoan tat! Khong co loi.")


# =============================================================
#  ENTRY POINT
# =============================================================

def main():
    """Hàm chính: phân tích tham số → đọc CSV → cập nhật DB."""

    # ── Phân tích tham số dòng lệnh ────────────────────────
    parser = argparse.ArgumentParser(
        description=(
            "Doc file CSV va cap nhat cot shortDesc "
            "trong bang ToolTranslation (PostgreSQL)."
        )
    )
    parser.add_argument(
        "--csv",
        default=DEFAULT_CSV_PATH,
        help=f"Duong dan toi file CSV (mac dinh: {DEFAULT_CSV_PATH})",
    )
    parser.add_argument(
        "--db-url",
        default=DATABASE_URL,
        help="Chuoi ket noi PostgreSQL",
    )
    parser.add_argument(
        "--locale",
        default=DEFAULT_LOCALE,
        help=f"Locale can cap nhat (mac dinh: {DEFAULT_LOCALE})",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Chi doc CSV va in ket qua, khong cap nhat DB",
    )
    args = parser.parse_args()

    # ── Bước 1: Đọc CSV ────────────────────────────────────
    df = read_csv_short_desc(args.csv)

    if df.empty:
        logger.warning("Khong co du lieu hop le trong CSV. Ket thuc.")
        return

    # ── Chế độ dry-run: chỉ xem trước, không ghi DB ───────
    if args.dry_run:
        logger.info("[DRY-RUN] Chi xem truoc, khong ghi vao DB.")
        logger.info(f"Xem truoc {min(5, len(df))} dong dau tien:")
        for _, row in df.head(5).iterrows():
            logger.info(f"  toolId={row['id']}")
            logger.info(f"  shortDesc={row['shortDesc'][:100]}...")
            logger.info("")
        return

    # ── Bước 2: Kết nối DB ─────────────────────────────────
    logger.info(f"Dang ket noi toi database...")
    engine = create_engine(args.db_url)

    # Kiểm tra kết nối
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    logger.info("Ket noi thanh cong!")

    # ── Bước 3: Cập nhật ToolTranslation ───────────────────
    logger.info(
        f"Bat dau cap nhat {len(df)} ban ghi "
        f"trong ToolTranslation (locale={args.locale})..."
    )
    stats = update_tool_translations(engine, df, args.locale)

    # ── Bước 4: In báo cáo ─────────────────────────────────
    print_summary(stats, args.locale)

    # Đóng engine
    engine.dispose()


if __name__ == "__main__":
    main()
