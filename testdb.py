"""
=============================================================
  Script: testdb.py
  Muc dich: Nhap ten Tool, tim trong DB va tra ve shortDesc
            tu bang ToolTranslation.
=============================================================

Cach chay:
  & .\.venv\Scripts\python.exe .\testdb.py
=============================================================
"""

import sys
import io

from sqlalchemy import create_engine, text

# ── Fix encoding cho Windows console ────────────────────────
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# ── Cau hinh ket noi DB ────────────────────────────────────
DATABASE_URL = "postgresql://postgres:8989@localhost:5432/new_db"


def search_by_name(engine, keyword: str):
    """
    Tim tool theo TEN (tim gan dung, khong phan biet hoa thuong).
    JOIN bang Tool va ToolTranslation de lay shortDesc (locale='en').

    Args:
        engine  : SQLAlchemy engine.
        keyword : Tu khoa tim trong ten tool (VD: "ChatLink", "Audio").
    """
    sql = text("""
        SELECT
            t."name"          AS tool_name,
            t."slug"          AS tool_slug,
            tt."locale"       AS locale,
            tt."shortDesc"    AS short_desc
        FROM "Tool" t
        JOIN "ToolTranslation" tt ON tt."toolId" = t."id"
        WHERE t."name" ILIKE :search_term
          AND tt."locale" = 'en'
        ORDER BY t."name"
        LIMIT 20
    """)

    with engine.connect() as conn:
        results = conn.execute(sql, {"search_term": f"%{keyword}%"})
        rows = [dict(r._mapping) for r in results]

    return rows


def search_by_content(engine, keyword: str):
    """
    Tim tool theo NOI DUNG shortDesc (tim gan dung, khong phan biet hoa thuong).
    Tra ve ten tool + shortDesc chua tu khoa.

    Args:
        engine  : SQLAlchemy engine.
        keyword : Tu khoa tim trong noi dung shortDesc.
    """
    sql = text("""
        SELECT
            t."name"          AS tool_name,
            t."slug"          AS tool_slug,
            tt."locale"       AS locale,
            tt."shortDesc"    AS short_desc
        FROM "Tool" t
        JOIN "ToolTranslation" tt ON tt."toolId" = t."id"
        WHERE tt."shortDesc" ILIKE :search_term
          AND tt."locale" = 'en'
        ORDER BY t."name"
        LIMIT 20
    """)

    with engine.connect() as conn:
        results = conn.execute(sql, {"search_term": f"%{keyword}%"})
        rows = [dict(r._mapping) for r in results]

    return rows


def print_results(rows, keyword):
    """In ket qua tim kiem ra man hinh."""
    if not rows:
        print(f"  Khong tim thay ket qua nao voi '{keyword}'.")
    else:
        print(f"\n  Tim thay {len(rows)} ket qua:\n")
        for i, row in enumerate(rows, 1):
            print(f"  [{i}] {row['tool_name']}")
            print(f"      Slug : {row['tool_slug']}")
            print(f"      Desc : {row['short_desc']}")
            print()


def main():
    """Vong lap chinh: chon che do tim kiem, nhap tu khoa, hien thi ket qua."""
    engine = create_engine(DATABASE_URL)

    # Kiem tra ket noi
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    print("Ket noi DB thanh cong!\n")

    print("=" * 55)
    print("  TIM KIEM TOOL - Xem shortDesc tu ToolTranslation")
    print("=" * 55)
    print("  Che do tim kiem:")
    print("    1 = Tim theo TEN tool")
    print("    2 = Tim theo NOI DUNG shortDesc")
    print("    q = Thoat")
    print("=" * 55)

    while True:
        # Chon che do tim kiem
        mode = input("\nChon che do (1/2/q): ").strip()

        # Thoat
        if mode.lower() == "q":
            print("Tam biet!")
            break

        # Kiem tra che do hop le
        if mode not in ("1", "2"):
            print("  Vui long chon 1, 2, hoac q.")
            continue

        # Nhap tu khoa
        keyword = input("Nhap tu khoa: ").strip()
        if not keyword:
            print("  Vui long nhap tu khoa.")
            continue

        # Tim kiem theo che do da chon
        if mode == "1":
            print(f"  Dang tim theo TEN tool: '{keyword}'...")
            rows = search_by_name(engine, keyword)
        else:
            print(f"  Dang tim theo NOI DUNG shortDesc: '{keyword}'...")
            rows = search_by_content(engine, keyword)

        # Hien thi ket qua
        print_results(rows, keyword)

    # Don dep
    engine.dispose()


if __name__ == "__main__":
    main()
