"""
=============================================================
  Script: dongbo.py
  Muc dich: Dong bo cot "name" tu bang Tool_en (DB A: mydb)
            sang bang Tool (DB B: new_db), map theo cot "id".
  Cong nghe: SQLAlchemy
=============================================================

Cach chay:
  & .\.venv\Scripts\python.exe .\dongbo.py

Xem truoc (khong ghi DB):
  & .\.venv\Scripts\python.exe .\dongbo.py --dry-run
=============================================================
"""

import sys
import io
import argparse
import logging
from datetime import datetime

from sqlalchemy import create_engine, text

# ── Fix encoding cho Windows console ────────────────────────
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# ── Cau hinh ket noi 2 database ─────────────────────────────
# DB A (nguon): chua bang Tool_en voi cot name day du
DB_A_URL = "postgresql://postgres:8989@localhost:5432/mydb"

# DB B (dich): chua bang Tool can cap nhat name
DB_B_URL = "postgresql://postgres:8989@localhost:5432/new_db"

# ── Cau hinh logging ───────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-7s | %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)


# =============================================================
#  HAM DOC DU LIEU TU DB NGUON
# =============================================================

def fetch_names_from_source(engine_a) -> dict:
    """
    Doc toan bo id va name tu bang Tool_en trong DB A (mydb).

    Returns:
        Dict {id: name} - mapping giua UUID va ten tool.
    """
    sql = text("""
        SELECT id, name
        FROM "Tool_en"
        WHERE name IS NOT NULL
          AND name != ''
    """)

    with engine_a.connect() as conn:
        results = conn.execute(sql)
        # Tao dict id -> name
        name_map = {row.id: row.name for row in results}

    logger.info(f"Doc duoc {len(name_map)} tool co name tu Tool_en (mydb).")
    return name_map


# =============================================================
#  HAM CAP NHAT VAO DB DICH
# =============================================================

def update_names_in_target(engine_b, name_map: dict) -> dict:
    """
    Cap nhat cot name trong bang Tool (DB B: new_db)
    dua theo id mapping tu DB A.

    Args:
        engine_b : SQLAlchemy engine ket noi DB B.
        name_map : Dict {id: name} tu DB A.

    Returns:
        Dict thong ke: updated, skipped, errors.
    """
    # Cau lenh UPDATE - chi cap nhat name theo id
    update_sql = text("""
        UPDATE "Tool"
        SET "name" = :new_name
        WHERE "id" = :tool_id
    """)

    stats = {"updated": 0, "skipped": 0, "errors": 0}

    # Su dung transaction de dam bao toan ven du lieu
    with engine_b.begin() as conn:
        for tool_id, tool_name in name_map.items():
            try:
                result = conn.execute(
                    update_sql,
                    {"new_name": tool_name, "tool_id": tool_id},
                )

                if result.rowcount > 0:
                    stats["updated"] += 1
                else:
                    # Id khong ton tai trong DB B
                    stats["skipped"] += 1

            except Exception as e:
                stats["errors"] += 1
                logger.error(f"  [ERROR] id={tool_id}: {e}")

    return stats


# =============================================================
#  IN BAO CAO
# =============================================================

def print_summary(stats: dict) -> None:
    """In bao cao tong ket sau khi dong bo."""
    logger.info("=" * 55)
    logger.info("  BAO CAO DONG BO NAME: Tool_en (mydb) -> Tool (new_db)")
    logger.info("=" * 55)
    logger.info(f"  So dong cap nhat : {stats['updated']}")
    logger.info(f"  So dong bo qua   : {stats['skipped']}  (id khong ton tai trong new_db)")
    logger.info(f"  So loi           : {stats['errors']}")
    logger.info("=" * 55)

    if stats["errors"] > 0:
        logger.warning("Co loi xay ra! Kiem tra log phia tren.")
    else:
        logger.info("Hoan tat! Khong co loi.")


# =============================================================
#  ENTRY POINT
# =============================================================

def main():
    """Ham chinh: doc name tu mydb -> cap nhat vao new_db."""

    # ── Phan tich tham so dong lenh ────────────────────────
    parser = argparse.ArgumentParser(
        description="Dong bo cot name tu Tool_en (mydb) sang Tool (new_db)."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Chi doc va hien thi, khong ghi vao DB dich",
    )
    parser.add_argument(
        "--db-source",
        default=DB_A_URL,
        help=f"DB nguon (mac dinh: mydb)",
    )
    parser.add_argument(
        "--db-target",
        default=DB_B_URL,
        help=f"DB dich (mac dinh: new_db)",
    )
    args = parser.parse_args()

    # ── Buoc 1: Ket noi DB nguon (mydb) ────────────────────
    logger.info("Dang ket noi DB nguon (mydb)...")
    engine_a = create_engine(args.db_source)
    with engine_a.connect() as conn:
        conn.execute(text("SELECT 1"))
    logger.info("Ket noi mydb thanh cong!")

    # ── Buoc 2: Doc name tu Tool_en ────────────────────────
    name_map = fetch_names_from_source(engine_a)

    if not name_map:
        logger.warning("Khong co du lieu name trong Tool_en. Ket thuc.")
        return

    # ── Che do dry-run: chi xem truoc ──────────────────────
    if args.dry_run:
        logger.info("[DRY-RUN] Chi xem truoc, khong ghi vao DB dich.")
        logger.info(f"Xem truoc 10 dong dau tien:")
        for i, (tid, tname) in enumerate(list(name_map.items())[:10], 1):
            logger.info(f"  [{i}] id={tid} -> name={tname}")
        return

    # ── Buoc 3: Ket noi DB dich (new_db) ───────────────────
    logger.info("Dang ket noi DB dich (new_db)...")
    engine_b = create_engine(args.db_target)
    with engine_b.connect() as conn:
        conn.execute(text("SELECT 1"))
    logger.info("Ket noi new_db thanh cong!")

    # ── Buoc 4: Cap nhat name vao bang Tool ────────────────
    logger.info(f"Bat dau dong bo {len(name_map)} ten tool...")
    stats = update_names_in_target(engine_b, name_map)

    # ── Buoc 5: In bao cao ─────────────────────────────────
    print_summary(stats)

    # Don dep
    engine_a.dispose()
    engine_b.dispose()


if __name__ == "__main__":
    main()
