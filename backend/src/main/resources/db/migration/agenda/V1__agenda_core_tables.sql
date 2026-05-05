-- ============================================================================
-- V1__agenda_core_tables.sql
-- Tablas base del módulo AGENDA (Sprint 1).
-- Schema: public  |  Prefijo: agenda_  |  Aislado del bot.
-- ============================================================================

-- Extensiones necesarias (idempotentes).
CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS unaccent;   -- búsqueda sin tildes

-- ----------------------------------------------------------------------------
-- agenda_users — usuarios finales del módulo AGENDA (admins de negocio + clientes).
-- No se fusiona con LeadEntity del bot (decisión de desacople total).
-- ----------------------------------------------------------------------------
CREATE TABLE agenda_users (
    id            UUID         NOT NULL DEFAULT gen_random_uuid(),
    tenant_id     VARCHAR(64)  NOT NULL,
    nombre        VARCHAR(255) NOT NULL,
    email         VARCHAR(255),
    telefono      VARCHAR(32),
    tipo_usuario  VARCHAR(16)  NOT NULL,            -- ADMIN | CLIENT
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at    TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT pk_agenda_users PRIMARY KEY (id),
    CONSTRAINT ck_agenda_users_tipo CHECK (tipo_usuario IN ('ADMIN','CLIENT')),
    CONSTRAINT uk_agenda_users_tenant_email UNIQUE (tenant_id, email)
);
CREATE INDEX idx_agenda_users_tenant ON agenda_users (tenant_id);

-- ----------------------------------------------------------------------------
-- agenda_categories — catálogo global. Sin tenant_id (compartido entre tenants).
-- synonyms (jsonb) centraliza el diccionario: "uñas","uñitas","mani" → manicure.
-- ----------------------------------------------------------------------------
CREATE TABLE agenda_categories (
    id          UUID         NOT NULL DEFAULT gen_random_uuid(),
    nombre      VARCHAR(120) NOT NULL,
    slug        VARCHAR(120) NOT NULL,
    icono       VARCHAR(64),
    synonyms    JSONB        NOT NULL DEFAULT '[]'::jsonb,
    activo      BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT pk_agenda_categories PRIMARY KEY (id),
    CONSTRAINT uk_agenda_categories_slug UNIQUE (slug)
);
CREATE INDEX idx_agenda_categories_synonyms_gin ON agenda_categories USING GIN (synonyms jsonb_path_ops);
CREATE INDEX idx_agenda_categories_activo ON agenda_categories (activo) WHERE activo = TRUE;

-- ----------------------------------------------------------------------------
-- agenda_businesses — negocios registrados por un admin de tenant.
-- search_tags (jsonb) guarda sinónimos específicos del negocio (nombre comercial,
-- barrio, keywords locales). deleted_at para soft delete.
-- ----------------------------------------------------------------------------
CREATE TABLE agenda_businesses (
    id             UUID         NOT NULL DEFAULT gen_random_uuid(),
    tenant_id      VARCHAR(64)  NOT NULL,
    nombre         VARCHAR(255) NOT NULL,
    descripcion    TEXT,
    owner_user_id  UUID,
    search_tags    JSONB        NOT NULL DEFAULT '[]'::jsonb,
    activo         BOOLEAN      NOT NULL DEFAULT TRUE,
    deleted_at     TIMESTAMP,
    created_at     TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at     TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT pk_agenda_businesses PRIMARY KEY (id),
    CONSTRAINT fk_agenda_businesses_owner
        FOREIGN KEY (owner_user_id) REFERENCES agenda_users (id) ON DELETE SET NULL
);
CREATE INDEX idx_agenda_businesses_tenant_activo ON agenda_businesses (tenant_id, activo) WHERE deleted_at IS NULL;
CREATE INDEX idx_agenda_businesses_nombre_lower ON agenda_businesses (LOWER(nombre));
CREATE INDEX idx_agenda_businesses_search_tags_gin ON agenda_businesses USING GIN (search_tags jsonb_path_ops);

-- ----------------------------------------------------------------------------
-- agenda_business_categories — pivote N:M con PK compuesta.
-- ----------------------------------------------------------------------------
CREATE TABLE agenda_business_categories (
    business_id  UUID       NOT NULL,
    category_id  UUID       NOT NULL,
    created_at   TIMESTAMP  NOT NULL DEFAULT now(),
    CONSTRAINT pk_agenda_business_categories PRIMARY KEY (business_id, category_id),
    CONSTRAINT fk_abc_business
        FOREIGN KEY (business_id) REFERENCES agenda_businesses (id) ON DELETE CASCADE,
    CONSTRAINT fk_abc_category
        FOREIGN KEY (category_id) REFERENCES agenda_categories (id) ON DELETE RESTRICT
);
CREATE INDEX idx_abc_category ON agenda_business_categories (category_id);

-- ----------------------------------------------------------------------------
-- agenda_services — servicios ofrecidos por un negocio (corte, manicura, clase).
-- ----------------------------------------------------------------------------
CREATE TABLE agenda_services (
    id            UUID         NOT NULL DEFAULT gen_random_uuid(),
    business_id   UUID         NOT NULL,
    nombre        VARCHAR(255) NOT NULL,
    descripcion   TEXT,
    duracion_min  INTEGER      NOT NULL,
    precio        NUMERIC(12,2),
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    deleted_at    TIMESTAMP,
    created_at    TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at    TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT pk_agenda_services PRIMARY KEY (id),
    CONSTRAINT fk_agenda_services_business
        FOREIGN KEY (business_id) REFERENCES agenda_businesses (id) ON DELETE CASCADE,
    CONSTRAINT ck_agenda_services_duracion CHECK (duracion_min > 0),
    CONSTRAINT ck_agenda_services_precio CHECK (precio IS NULL OR precio >= 0)
);
CREATE INDEX idx_agenda_services_business_activo ON agenda_services (business_id, activo) WHERE deleted_at IS NULL;

-- ----------------------------------------------------------------------------
-- agenda_business_settings — configuración operativa por negocio (1:1).
-- ----------------------------------------------------------------------------
CREATE TABLE agenda_business_settings (
    business_id                 UUID      NOT NULL,
    hours_cancellation_limit    INTEGER   NOT NULL DEFAULT 4,
    loyalty_min_attendances     INTEGER   NOT NULL DEFAULT 3,
    loyalty_window_days         INTEGER   NOT NULL DEFAULT 30,
    expiration_alert_days       INTEGER   NOT NULL DEFAULT 7,
    expiration_alert_credits    INTEGER   NOT NULL DEFAULT 2,
    auto_notify_enabled         BOOLEAN   NOT NULL DEFAULT TRUE,
    created_at                  TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT pk_agenda_business_settings PRIMARY KEY (business_id),
    CONSTRAINT fk_agenda_business_settings_business
        FOREIGN KEY (business_id) REFERENCES agenda_businesses (id) ON DELETE CASCADE,
    CONSTRAINT ck_abs_cancellation CHECK (hours_cancellation_limit >= 0),
    CONSTRAINT ck_abs_loyalty_min CHECK (loyalty_min_attendances > 0),
    CONSTRAINT ck_abs_loyalty_window CHECK (loyalty_window_days > 0)
);

-- ----------------------------------------------------------------------------
-- agenda_tenant_config — feature flags y config de AGENDA por tenant.
-- Aislado del sistema del bot (no toca feature_config ni bot_entity).
-- ----------------------------------------------------------------------------
CREATE TABLE agenda_tenant_config (
    tenant_id                VARCHAR(64) NOT NULL,
    agenda_enabled           BOOLEAN     NOT NULL DEFAULT FALSE,
    public_search_enabled    BOOLEAN     NOT NULL DEFAULT TRUE,
    loyalty_engine_enabled   BOOLEAN     NOT NULL DEFAULT TRUE,
    auto_notifications       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at               TIMESTAMP   NOT NULL DEFAULT now(),
    updated_at               TIMESTAMP   NOT NULL DEFAULT now(),
    CONSTRAINT pk_agenda_tenant_config PRIMARY KEY (tenant_id)
);
