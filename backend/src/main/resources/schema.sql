-- PostgreSQL schema for Enterprise Chatbot Engine (pensado para arranque desde 0: borrar volumen y reconstruir)
-- pgvector para RAG (imagen Docker debe ser pgvector/pgvector:pg16)
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS conversation (
    conversation_id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    channel_id VARCHAR(64) NOT NULL,
    current_intent VARCHAR(128),
    updated_at BIGINT
);

CREATE TABLE IF NOT EXISTS conversation_context (
    conversation_id VARCHAR(255) NOT NULL REFERENCES conversation(conversation_id) ON DELETE CASCADE,
    context_key VARCHAR(255) NOT NULL,
    context_value TEXT,
    PRIMARY KEY (conversation_id, context_key)
);

CREATE TABLE IF NOT EXISTS message (
    id BIGSERIAL PRIMARY KEY,
    conversation_id VARCHAR(255) NOT NULL,
    role VARCHAR(16) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_message_conversation ON message(conversation_id);
CREATE INDEX IF NOT EXISTS idx_message_created ON message(created_at);

CREATE TABLE IF NOT EXISTS faq (
    id BIGSERIAL PRIMARY KEY,
    intent VARCHAR(128) NOT NULL,
    keywords TEXT NOT NULL,
    response TEXT NOT NULL,
    use_regex BOOLEAN NOT NULL DEFAULT FALSE,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_faq_intent ON faq(intent);
CREATE INDEX IF NOT EXISTS idx_faq_active ON faq(active);

CREATE TABLE IF NOT EXISTS feature_config (
    id BIGSERIAL PRIMARY KEY,
    tenant_id VARCHAR(64) NOT NULL,
    feature_key VARCHAR(64) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE(tenant_id, feature_key)
);

CREATE INDEX IF NOT EXISTS idx_feature_tenant ON feature_config(tenant_id, feature_key);

CREATE TABLE IF NOT EXISTS lead (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    source VARCHAR(64),
    user_id VARCHAR(255),
    created_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_lead_email ON lead(email);
CREATE INDEX IF NOT EXISTS idx_lead_created ON lead(created_at);

-- Menus: menús interactivos configurables por tenant
CREATE TABLE IF NOT EXISTS menu (
    id BIGSERIAL PRIMARY KEY,
    tenant_id VARCHAR(64) NOT NULL,
    menu_key VARCHAR(64) NOT NULL,
    text TEXT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE(tenant_id, menu_key)
);

CREATE INDEX IF NOT EXISTS idx_menu_tenant ON menu(tenant_id);

-- Menu options: opciones de cada menú
CREATE TABLE IF NOT EXISTS menu_option (
    id BIGSERIAL PRIMARY KEY,
    menu_id BIGINT NOT NULL REFERENCES menu(id) ON DELETE CASCADE,
    option_key VARCHAR(16) NOT NULL,
    target_menu_key VARCHAR(64) NOT NULL,
    label VARCHAR(255) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_menu_option_menu ON menu_option(menu_id);

-- Menu triggers: palabras que activan un menú (ej: "hola" -> "main")
CREATE TABLE IF NOT EXISTS menu_trigger (
    id BIGSERIAL PRIMARY KEY,
    tenant_id VARCHAR(64) NOT NULL,
    trigger_word VARCHAR(64) NOT NULL,
    menu_key VARCHAR(64) NOT NULL,
    UNIQUE(tenant_id, trigger_word)
);

CREATE INDEX IF NOT EXISTS idx_menu_trigger_tenant ON menu_trigger(tenant_id);

-- RAG: fragmentos de conocimiento (multi-tenant)
CREATE TABLE IF NOT EXISTS knowledge_chunk (
    id BIGSERIAL PRIMARY KEY,
    tenant_id VARCHAR(64) NOT NULL,
    topic VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    keywords TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    embedding vector(768)
);
CREATE INDEX IF NOT EXISTS idx_knowledge_tenant ON knowledge_chunk(tenant_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_topic ON knowledge_chunk(topic);
CREATE INDEX IF NOT EXISTS idx_knowledge_active ON knowledge_chunk(active);
-- Por si la tabla fue creada por Hibernate (ddl-auto: update) sin la columna vector
ALTER TABLE knowledge_chunk ADD COLUMN IF NOT EXISTS embedding vector(768);

-- Bot: configuración de cada bot por usuario
CREATE TABLE IF NOT EXISTS bot (
    id BIGSERIAL PRIMARY KEY,
    tenant_id VARCHAR(64) NOT NULL UNIQUE,
    user_id VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(500),
    tier VARCHAR(32) NOT NULL DEFAULT 'tier1',
    faq_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    ai_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    actions_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    whatsapp_phone_number_id VARCHAR(64),
    whatsapp_access_token TEXT,
    whatsapp_verify_token VARCHAR(128),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bot_user ON bot(user_id);
CREATE INDEX IF NOT EXISTS idx_bot_tenant ON bot(tenant_id);
