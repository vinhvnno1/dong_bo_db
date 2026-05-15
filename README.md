# TopAICollection - Test Database

Hai file SQL để dựng database mẫu cho trang chi tiết công cụ AI (giống `/vi/tool/elevenlabs` trong HTML bạn gửi).

## File

- `topaicollection_schema.sql` — PostgreSQL (đã test chạy ok)
- `topaicollection_schema_mysql.sql` — MySQL 8.0+

## Schema

3 bảng:

- **categories** — danh mục (audio, video, writing, image, coding, chatbot, productivity, design)
- **tools** — công cụ AI (10 records: ElevenLabs, ChatGPT, Midjourney, Claude, Stable Diffusion, GitHub Copilot, Jasper, Runway, Notion AI, Perplexity)
- **tool_categories** — N-N giữa tool và category, có cờ `is_primary` đánh dấu category chính

Trường trong `tools` map vào các phần của trang web:
- `name`, `logo_url`, `website` → header
- `short_desc`, `what_is` → phần "Giới thiệu công cụ" và "ElevenLabs là gì?"
- `average_rating`, `review_count` → stars + "(17 đánh giá)"
- `monthly_visits`, `growth_rate` → khối Phân tích
- `is_featured`, `is_sponsored`, `is_new`, `is_trending` → các badge

## Chạy

PostgreSQL:
```bash
psql -U postgres -d your_db -f topaicollection_schema.sql
```

MySQL:
```bash
mysql -u root -p your_db < topaicollection_schema_mysql.sql
```

Cả hai script đều `DROP TABLE IF EXISTS` trước, nên chạy lại nhiều lần ok.

## Query mẫu

Cuối file PostgreSQL có sẵn 5 query comment cho:
1. Chi tiết 1 tool (trang `/tool/[slug]`)
2. Featured tools cho trang chủ
3. Trending tools
4. Tools theo category
5. Alternatives (tools cùng category)

## Mở rộng

Nếu cần thêm reviews, tags, users, analytics chi tiết theo ngày... cứ nói, tôi mở rộng tiếp.
