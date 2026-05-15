-- =============================================================
--  TopAICollection - Test Database (MySQL 8.0+)
--  Phiên bản MySQL của topaicollection_schema.sql
-- =============================================================

DROP TABLE IF EXISTS tool_categories;
DROP TABLE IF EXISTS tools;
DROP TABLE IF EXISTS categories;

-- =============================================================
-- BẢNG: categories
-- =============================================================
CREATE TABLE categories (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    slug         VARCHAR(100)  NOT NULL UNIQUE,
    name         VARCHAR(150)  NOT NULL,
    description  TEXT,
    icon         VARCHAR(100),
    tool_count   INT           NOT NULL DEFAULT 0,
    is_featured  BOOLEAN       NOT NULL DEFAULT false,
    sort_order   INT           NOT NULL DEFAULT 0,
    created_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_categories_slug (slug),
    INDEX idx_categories_featured (is_featured)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================
-- BẢNG: tools
-- =============================================================
CREATE TABLE tools (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    slug              VARCHAR(150)  NOT NULL UNIQUE,
    name              VARCHAR(200)  NOT NULL,
    website           VARCHAR(500)  NOT NULL,
    logo_url          VARCHAR(500),
    short_desc        VARCHAR(300),
    what_is           TEXT,
    introduction      TEXT,

    average_rating    DECIMAL(3,2)  NOT NULL DEFAULT 0,
    review_count      INT           NOT NULL DEFAULT 0,

    monthly_visits    BIGINT        NOT NULL DEFAULT 0,
    growth_rate       DECIMAL(6,2)  NOT NULL DEFAULT 0,

    pricing_type      VARCHAR(30)   NOT NULL DEFAULT 'freemium',
    starting_price    DECIMAL(10,2),

    is_featured       BOOLEAN       NOT NULL DEFAULT false,
    is_sponsored      BOOLEAN       NOT NULL DEFAULT false,
    is_new            BOOLEAN       NOT NULL DEFAULT false,
    is_trending       BOOLEAN       NOT NULL DEFAULT false,

    launched_at       DATE,
    created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT chk_rating  CHECK (average_rating BETWEEN 0 AND 5),
    CONSTRAINT chk_pricing CHECK (pricing_type IN ('free','freemium','paid','contact')),

    INDEX idx_tools_slug     (slug),
    INDEX idx_tools_featured (is_featured),
    INDEX idx_tools_trending (is_trending),
    INDEX idx_tools_rating   (average_rating DESC),
    INDEX idx_tools_visits   (monthly_visits DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================
-- BẢNG: tool_categories
-- =============================================================
CREATE TABLE tool_categories (
    tool_id      INT NOT NULL,
    category_id  INT NOT NULL,
    is_primary   BOOLEAN NOT NULL DEFAULT false,
    PRIMARY KEY (tool_id, category_id),
    FOREIGN KEY (tool_id)     REFERENCES tools(id)      ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
    INDEX idx_tc_category (category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


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
-- SEED: tools
-- =============================================================
INSERT INTO tools
    (slug, name, website, logo_url, short_desc, what_is,
     average_rating, review_count, monthly_visits, growth_rate,
     pricing_type, starting_price,
     is_featured, is_sponsored, is_new, is_trending, launched_at) VALUES

('elevenlabs', 'ElevenLabs', 'https://elevenlabs.io/',
 'https://logo.clearbit.com/elevenlabs.io',
 'Nền tảng AI giọng nói hàng đầu cho text-to-speech, voice cloning, dubbing.',
 'ElevenLabs là nền tảng AI âm thanh cung cấp text-to-speech siêu thực, nhân bản giọng nói, lồng tiếng video bằng AI, AI hội thoại và tạo hiệu ứng âm thanh trên 29+ ngôn ngữ.',
 4.70, 17, 82000000, 12.50, 'freemium', 5.00, true, false, false, true, '2022-01-15'),

('chatgpt', 'ChatGPT', 'https://chat.openai.com/',
 'https://logo.clearbit.com/openai.com',
 'Trợ lý AI hội thoại của OpenAI, dùng được cho viết, phân tích, lập trình.',
 'ChatGPT là chatbot AI do OpenAI phát triển dựa trên các mô hình GPT.',
 4.80, 12345, 4500000000, 5.20, 'freemium', 20.00, true, true, false, true, '2022-11-30'),

('midjourney', 'Midjourney', 'https://www.midjourney.com/',
 'https://logo.clearbit.com/midjourney.com',
 'AI tạo ảnh chất lượng cao từ mô tả văn bản.',
 'Midjourney là dịch vụ AI tạo hình ảnh từ prompt văn bản, hoạt động qua Discord và web.',
 4.60, 8902, 23000000, 3.10, 'paid', 10.00, true, false, false, false, '2022-07-12'),

('claude', 'Claude', 'https://claude.ai/',
 'https://logo.clearbit.com/anthropic.com',
 'Trợ lý AI của Anthropic, tập trung vào an toàn và lý luận dài.',
 'Claude là trợ lý AI của Anthropic, mạnh ở phân tích văn bản dài, lập luận và viết.',
 4.75, 5678, 350000000, 18.40, 'freemium', 17.00, true, false, true, true, '2023-03-14'),

('stable-diffusion', 'Stable Diffusion', 'https://stability.ai/',
 'https://logo.clearbit.com/stability.ai',
 'Mô hình tạo ảnh mã nguồn mở, tùy biến mạnh.',
 'Stable Diffusion là mô hình text-to-image mã nguồn mở của Stability AI.',
 4.40, 4321, 12000000, -2.50, 'free', 0.00, false, false, false, false, '2022-08-22'),

('github-copilot', 'GitHub Copilot', 'https://github.com/features/copilot',
 'https://logo.clearbit.com/github.com',
 'Trợ lý AI lập trình tích hợp IDE, gợi ý code thời gian thực.',
 'GitHub Copilot là trợ lý lập trình AI do GitHub và OpenAI phát triển.',
 4.55, 9876, 45000000, 7.80, 'paid', 10.00, true, false, false, true, '2021-10-29'),

('jasper', 'Jasper', 'https://www.jasper.ai/',
 'https://logo.clearbit.com/jasper.ai',
 'Nền tảng AI viết nội dung cho marketing và doanh nghiệp.',
 'Jasper là nền tảng AI viết nội dung tập trung vào marketing.',
 4.20, 2345, 3800000, -8.10, 'paid', 49.00, false, false, false, false, '2021-02-01'),

('runway', 'Runway', 'https://runwayml.com/',
 'https://logo.clearbit.com/runwayml.com',
 'Bộ công cụ AI sáng tạo cho video, ảnh và hiệu ứng.',
 'Runway cung cấp các công cụ AI sáng tạo cho video (text-to-video, inpainting, motion).',
 4.50, 3210, 9500000, 22.30, 'freemium', 15.00, true, false, true, true, '2018-01-01'),

('notion-ai', 'Notion AI', 'https://www.notion.so/product/ai',
 'https://logo.clearbit.com/notion.so',
 'Trợ lý AI tích hợp ngay trong workspace Notion.',
 'Notion AI tích hợp vào Notion, hỗ trợ tóm tắt, viết, dịch và tìm thông tin.',
 4.30, 1890, 18000000, 6.40, 'freemium', 10.00, false, false, false, false, '2023-02-22'),

('perplexity', 'Perplexity', 'https://www.perplexity.ai/',
 'https://logo.clearbit.com/perplexity.ai',
 'Công cụ tìm kiếm AI trả lời kèm nguồn trích dẫn.',
 'Perplexity là engine tìm kiếm AI, trả lời câu hỏi bằng văn bản có trích dẫn nguồn.',
 4.65, 4567, 95000000, 35.70, 'freemium', 20.00, true, false, true, true, '2022-12-07');


-- =============================================================
-- SEED: tool_categories
-- =============================================================
INSERT INTO tool_categories (tool_id, category_id, is_primary)
SELECT t.id, c.id, m.is_primary FROM (
    SELECT 'elevenlabs'       AS tool_slug, 'audio'        AS category_slug, true  AS is_primary UNION ALL
    SELECT 'elevenlabs',                    'productivity',                  false UNION ALL
    SELECT 'chatgpt',                       'chatbot',                       true  UNION ALL
    SELECT 'chatgpt',                       'productivity',                  false UNION ALL
    SELECT 'chatgpt',                       'writing',                       false UNION ALL
    SELECT 'midjourney',                    'image',                         true  UNION ALL
    SELECT 'midjourney',                    'design',                        false UNION ALL
    SELECT 'claude',                        'chatbot',                       true  UNION ALL
    SELECT 'claude',                        'writing',                       false UNION ALL
    SELECT 'claude',                        'coding',                        false UNION ALL
    SELECT 'stable-diffusion',              'image',                         true  UNION ALL
    SELECT 'github-copilot',                'coding',                        true  UNION ALL
    SELECT 'github-copilot',                'productivity',                  false UNION ALL
    SELECT 'jasper',                        'writing',                       true  UNION ALL
    SELECT 'runway',                        'video',                         true  UNION ALL
    SELECT 'runway',                        'image',                         false UNION ALL
    SELECT 'notion-ai',                     'productivity',                  true  UNION ALL
    SELECT 'notion-ai',                     'writing',                       false UNION ALL
    SELECT 'perplexity',                    'productivity',                  true  UNION ALL
    SELECT 'perplexity',                    'writing',                       false
) AS m
JOIN tools      t ON t.slug = m.tool_slug
JOIN categories c ON c.slug = m.category_slug;


-- =============================================================
-- Cập nhật cache tool_count
-- =============================================================
UPDATE categories c
SET tool_count = (SELECT COUNT(*) FROM tool_categories tc WHERE tc.category_id = c.id);
