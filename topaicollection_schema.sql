-- =============================================================
--  TopAICollection - Test Database (PostgreSQL)
--  Bao gồm: schema + seed data (~10 tools + categories)
--  Mục đích: Test hiển thị trang /tool/[slug] và /category/[slug]
-- =============================================================

-- Xóa bảng cũ nếu tồn tại (chạy lại nhiều lần được)
DROP TABLE IF EXISTS tool_categories CASCADE;
DROP TABLE IF EXISTS tools CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

-- =============================================================
-- BẢNG: categories
-- =============================================================
CREATE TABLE categories (
    id           SERIAL PRIMARY KEY,
    slug         VARCHAR(100)  NOT NULL UNIQUE,
    name         VARCHAR(150)  NOT NULL,
    description  TEXT,
    icon         VARCHAR(100),                      -- iconify name, vd: "ph:rocket-launch"
    tool_count   INTEGER       NOT NULL DEFAULT 0,  -- cache: số tool trong category
    is_featured  BOOLEAN       NOT NULL DEFAULT false,
    sort_order   INTEGER       NOT NULL DEFAULT 0,
    created_at   TIMESTAMP     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_categories_slug      ON categories(slug);
CREATE INDEX idx_categories_featured  ON categories(is_featured);

-- =============================================================
-- BẢNG: tools
-- =============================================================
CREATE TABLE tools (
    id                SERIAL PRIMARY KEY,
    slug              VARCHAR(150)  NOT NULL UNIQUE,    -- vd: "elevenlabs"
    name              VARCHAR(200)  NOT NULL,           -- vd: "ElevenLabs"
    website           VARCHAR(500)  NOT NULL,           -- URL chính thức
    logo_url          VARCHAR(500),                     -- icon/logo
    short_desc        VARCHAR(300),                     -- mô tả ngắn cho card
    what_is           TEXT,                             -- nội dung "X là gì?"
    introduction      TEXT,                             -- giới thiệu dài

    -- Đánh giá
    average_rating    NUMERIC(3,2)  NOT NULL DEFAULT 0, -- 0.00 - 5.00
    review_count      INTEGER       NOT NULL DEFAULT 0,

    -- Lưu lượng / phân tích
    monthly_visits    BIGINT        NOT NULL DEFAULT 0, -- tổng visits/tháng
    growth_rate       NUMERIC(6,2)  NOT NULL DEFAULT 0, -- %, có thể âm

    -- Pricing
    pricing_type      VARCHAR(30)   NOT NULL DEFAULT 'freemium',
                                                       -- free | freemium | paid | contact
    starting_price    NUMERIC(10,2),                   -- USD/tháng, NULL = không công bố

    -- Flags hiển thị
    is_featured       BOOLEAN       NOT NULL DEFAULT false,
    is_sponsored      BOOLEAN       NOT NULL DEFAULT false,
    is_new            BOOLEAN       NOT NULL DEFAULT false,
    is_trending       BOOLEAN       NOT NULL DEFAULT false,

    -- Timestamps
    launched_at       DATE,                            -- ngày ra mắt thực tế
    created_at        TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP     NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_rating  CHECK (average_rating BETWEEN 0 AND 5),
    CONSTRAINT chk_pricing CHECK (pricing_type IN ('free','freemium','paid','contact'))
);

CREATE INDEX idx_tools_slug        ON tools(slug);
CREATE INDEX idx_tools_featured    ON tools(is_featured);
CREATE INDEX idx_tools_trending    ON tools(is_trending);
CREATE INDEX idx_tools_rating      ON tools(average_rating DESC);
CREATE INDEX idx_tools_visits      ON tools(monthly_visits DESC);

-- =============================================================
-- BẢNG: tool_categories  (quan hệ N-N)
-- =============================================================
CREATE TABLE tool_categories (
    tool_id      INTEGER NOT NULL REFERENCES tools(id)      ON DELETE CASCADE,
    category_id  INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    is_primary   BOOLEAN NOT NULL DEFAULT false,            -- category chính của tool
    PRIMARY KEY (tool_id, category_id)
);

CREATE INDEX idx_tc_category ON tool_categories(category_id);


-- =============================================================
-- SEED: categories
-- =============================================================
INSERT INTO categories (slug, name, description, icon, is_featured, sort_order) VALUES
('audio',        'AI Âm thanh',     'Công cụ AI cho text-to-speech, voice cloning, dubbing',  'ph:speaker-high',     true,  1),
('video',        'AI Video',        'Công cụ tạo, chỉnh sửa và phân tích video bằng AI',      'ph:video-camera',     true,  2),
('writing',      'AI Viết lách',    'Trợ lý viết, copywriting và tạo nội dung',               'ph:pencil-line',      true,  3),
('image',        'AI Hình ảnh',     'Tạo và chỉnh sửa ảnh bằng AI',                           'ph:image',            true,  4),
('coding',       'AI Lập trình',    'Trợ lý code, tự động hoàn thành và review',              'ph:code',             true,  5),
('chatbot',      'AI Chatbot',      'Trợ lý hội thoại và chatbot',                            'ph:chat-circle-dots', false, 6),
('productivity', 'AI Năng suất',    'Công cụ tăng năng suất công việc',                       'ph:rocket-launch',    false, 7),
('design',       'AI Thiết kế',     'Hỗ trợ thiết kế UI/UX, đồ họa',                          'ph:palette',          false, 8);


-- =============================================================
-- SEED: tools (10 tools)
-- =============================================================
INSERT INTO tools
    (slug, name, website, logo_url, short_desc, what_is,
     average_rating, review_count, monthly_visits, growth_rate,
     pricing_type, starting_price,
     is_featured, is_sponsored, is_new, is_trending, launched_at) VALUES

('elevenlabs', 'ElevenLabs',
 'https://elevenlabs.io/',
 'https://logo.clearbit.com/elevenlabs.io',
 'Nền tảng AI giọng nói hàng đầu cho text-to-speech, voice cloning, dubbing.',
 'ElevenLabs là nền tảng AI âm thanh cung cấp text-to-speech siêu thực, nhân bản giọng nói, lồng tiếng video bằng AI, AI hội thoại và tạo hiệu ứng âm thanh trên 29+ ngôn ngữ.',
 4.70, 17,  82000000,  12.50, 'freemium',  5.00,  true,  false, false, true,  '2022-01-15'),

('chatgpt', 'ChatGPT',
 'https://chat.openai.com/',
 'https://logo.clearbit.com/openai.com',
 'Trợ lý AI hội thoại của OpenAI, dùng được cho viết, phân tích, lập trình.',
 'ChatGPT là chatbot AI do OpenAI phát triển dựa trên các mô hình GPT, hỗ trợ trả lời, viết, dịch, lập trình và nhiều tác vụ khác.',
 4.80, 12345, 4500000000, 5.20, 'freemium', 20.00, true,  true,  false, true,  '2022-11-30'),

('midjourney', 'Midjourney',
 'https://www.midjourney.com/',
 'https://logo.clearbit.com/midjourney.com',
 'AI tạo ảnh chất lượng cao từ mô tả văn bản.',
 'Midjourney là dịch vụ AI tạo hình ảnh từ prompt văn bản, nổi tiếng về chất lượng nghệ thuật, hoạt động chính qua Discord và web.',
 4.60, 8902, 23000000,  3.10, 'paid',    10.00, true,  false, false, false, '2022-07-12'),

('claude', 'Claude',
 'https://claude.ai/',
 'https://logo.clearbit.com/anthropic.com',
 'Trợ lý AI của Anthropic, tập trung vào an toàn và lý luận dài.',
 'Claude là trợ lý AI của Anthropic, mạnh ở phân tích văn bản dài, lập luận và viết, có sẵn trên web, mobile và API.',
 4.75, 5678, 350000000, 18.40, 'freemium', 17.00, true,  false, true,  true,  '2023-03-14'),

('stable-diffusion', 'Stable Diffusion',
 'https://stability.ai/',
 'https://logo.clearbit.com/stability.ai',
 'Mô hình tạo ảnh mã nguồn mở, tùy biến mạnh.',
 'Stable Diffusion là mô hình text-to-image mã nguồn mở của Stability AI, có thể chạy local, hỗ trợ nhiều fine-tune và LoRA.',
 4.40, 4321, 12000000, -2.50, 'free',     0.00,  false, false, false, false, '2022-08-22'),

('github-copilot', 'GitHub Copilot',
 'https://github.com/features/copilot',
 'https://logo.clearbit.com/github.com',
 'Trợ lý AI lập trình tích hợp IDE, gợi ý code thời gian thực.',
 'GitHub Copilot là trợ lý lập trình AI do GitHub và OpenAI phát triển, gợi ý code theo ngữ cảnh trong VS Code, JetBrains và nhiều IDE khác.',
 4.55, 9876, 45000000,  7.80, 'paid',    10.00, true,  false, false, true,  '2021-10-29'),

('jasper', 'Jasper',
 'https://www.jasper.ai/',
 'https://logo.clearbit.com/jasper.ai',
 'Nền tảng AI viết nội dung cho marketing và doanh nghiệp.',
 'Jasper là nền tảng AI viết nội dung tập trung vào marketing, hỗ trợ blog, ads, email và quản lý brand voice.',
 4.20, 2345, 3800000,  -8.10, 'paid',    49.00, false, false, false, false, '2021-02-01'),

('runway', 'Runway',
 'https://runwayml.com/',
 'https://logo.clearbit.com/runwayml.com',
 'Bộ công cụ AI sáng tạo cho video, ảnh và hiệu ứng.',
 'Runway cung cấp các công cụ AI sáng tạo cho video (text-to-video, inpainting, motion), được dùng nhiều trong sản xuất nội dung.',
 4.50, 3210, 9500000,  22.30, 'freemium', 15.00, true,  false, true,  true,  '2018-01-01'),

('notion-ai', 'Notion AI',
 'https://www.notion.so/product/ai',
 'https://logo.clearbit.com/notion.so',
 'Trợ lý AI tích hợp ngay trong workspace Notion.',
 'Notion AI tích hợp vào Notion, hỗ trợ tóm tắt, viết, dịch và tìm thông tin trong workspace của bạn.',
 4.30, 1890,  18000000,  6.40, 'freemium', 10.00, false, false, false, false, '2023-02-22'),

('perplexity', 'Perplexity',
 'https://www.perplexity.ai/',
 'https://logo.clearbit.com/perplexity.ai',
 'Công cụ tìm kiếm AI trả lời kèm nguồn trích dẫn.',
 'Perplexity là engine tìm kiếm AI, trả lời câu hỏi bằng văn bản có trích dẫn nguồn, hỗ trợ nhiều chế độ tìm kiếm chuyên sâu.',
 4.65, 4567, 95000000,  35.70, 'freemium', 20.00, true,  false, true,  true,  '2022-12-07');


-- =============================================================
-- SEED: tool_categories  (mỗi tool 1-2 category, 1 cái là primary)
-- =============================================================
INSERT INTO tool_categories (tool_id, category_id, is_primary)
SELECT t.id, c.id, m.is_primary FROM (VALUES
    -- (tool_slug,        category_slug,  is_primary)
    ('elevenlabs',       'audio',        true),
    ('elevenlabs',       'productivity', false),

    ('chatgpt',          'chatbot',      true),
    ('chatgpt',          'productivity', false),
    ('chatgpt',          'writing',      false),

    ('midjourney',       'image',        true),
    ('midjourney',       'design',       false),

    ('claude',           'chatbot',      true),
    ('claude',           'writing',      false),
    ('claude',           'coding',       false),

    ('stable-diffusion', 'image',        true),

    ('github-copilot',   'coding',       true),
    ('github-copilot',   'productivity', false),

    ('jasper',           'writing',      true),

    ('runway',           'video',        true),
    ('runway',           'image',        false),

    ('notion-ai',        'productivity', true),
    ('notion-ai',        'writing',      false),

    ('perplexity',       'productivity', true),
    ('perplexity',       'writing',      false)
) AS m(tool_slug, category_slug, is_primary)
JOIN tools      t ON t.slug = m.tool_slug
JOIN categories c ON c.slug = m.category_slug;


-- =============================================================
-- Cập nhật cache: categories.tool_count
-- =============================================================
UPDATE categories c SET tool_count = (
    SELECT COUNT(*) FROM tool_categories tc WHERE tc.category_id = c.id
);


-- =============================================================
-- KIỂM TRA NHANH (chạy thử các query trang web cần)
-- =============================================================

-- 1. Lấy chi tiết 1 tool (giống trang /tool/elevenlabs)
-- SELECT t.*,
--        ARRAY_AGG(c.name) AS categories
-- FROM tools t
-- LEFT JOIN tool_categories tc ON tc.tool_id = t.id
-- LEFT JOIN categories c       ON c.id      = tc.category_id
-- WHERE t.slug = 'elevenlabs'
-- GROUP BY t.id;

-- 2. Featured tools cho trang chủ
-- SELECT slug, name, short_desc, average_rating, monthly_visits
-- FROM tools WHERE is_featured = true
-- ORDER BY monthly_visits DESC LIMIT 10;

-- 3. Trending tools
-- SELECT slug, name, growth_rate FROM tools
-- WHERE is_trending = true ORDER BY growth_rate DESC;

-- 4. Tools theo category
-- SELECT t.slug, t.name, t.average_rating FROM tools t
-- JOIN tool_categories tc ON tc.tool_id = t.id
-- JOIN categories c       ON c.id      = tc.category_id
-- WHERE c.slug = 'image' ORDER BY t.monthly_visits DESC;

-- 5. Alternatives (cùng primary category, khác tool hiện tại)
-- SELECT t2.slug, t2.name, t2.average_rating
-- FROM tools t1
-- JOIN tool_categories tc1 ON tc1.tool_id = t1.id AND tc1.is_primary
-- JOIN tool_categories tc2 ON tc2.category_id = tc1.category_id AND tc2.is_primary
-- JOIN tools t2 ON t2.id = tc2.tool_id AND t2.id != t1.id
-- WHERE t1.slug = 'elevenlabs' LIMIT 6;
