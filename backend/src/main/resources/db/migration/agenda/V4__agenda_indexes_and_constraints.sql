-- ============================================================================
-- V4 — Índices, FKs, CHECKs y objetos que JPA no puede modelar (parciales, GIN,
-- expresiones). Idempotente: seguro en DB vacía o ya creada por Hibernate.
-- Esquema de tablas = entidades JPA; este script solo completa lo del SQL legacy.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- agenda_idempotency_keys (sin entidad JPA; usada por AgendaIdempotencyFilter)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS agenda_idempotency_keys (
    idempotency_key VARCHAR(128)  PRIMARY KEY,
    status_code     INT           NOT NULL,
    response_body   TEXT          NOT NULL,
    created_at      TIMESTAMP     NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agenda_idempotency_created
    ON agenda_idempotency_keys (created_at);

-- ----------------------------------------------------------------------------
-- FKs (Hibernate no las crea con el patrón UUID sin @ManyToOne)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_agenda_businesses_owner') THEN
        ALTER TABLE agenda_businesses
            ADD CONSTRAINT fk_agenda_businesses_owner
                FOREIGN KEY (owner_user_id) REFERENCES agenda_users (id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_abc_business') THEN
        ALTER TABLE agenda_business_categories
            ADD CONSTRAINT fk_abc_business
                FOREIGN KEY (business_id) REFERENCES agenda_businesses (id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_abc_category') THEN
        ALTER TABLE agenda_business_categories
            ADD CONSTRAINT fk_abc_category
                FOREIGN KEY (category_id) REFERENCES agenda_categories (id) ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_agenda_services_business') THEN
        ALTER TABLE agenda_services
            ADD CONSTRAINT fk_agenda_services_business
                FOREIGN KEY (business_id) REFERENCES agenda_businesses (id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_agenda_business_settings_business') THEN
        ALTER TABLE agenda_business_settings
            ADD CONSTRAINT fk_agenda_business_settings_business
                FOREIGN KEY (business_id) REFERENCES agenda_businesses (id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_agenda_plans_business') THEN
        ALTER TABLE agenda_plans
            ADD CONSTRAINT fk_agenda_plans_business
                FOREIGN KEY (business_id) REFERENCES agenda_businesses (id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_aus_user') THEN
        ALTER TABLE agenda_user_subscriptions
            ADD CONSTRAINT fk_aus_user
                FOREIGN KEY (user_id) REFERENCES agenda_users (id) ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_aus_plan') THEN
        ALTER TABLE agenda_user_subscriptions
            ADD CONSTRAINT fk_aus_plan
                FOREIGN KEY (plan_id) REFERENCES agenda_plans (id) ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_aus_business') THEN
        ALTER TABLE agenda_user_subscriptions
            ADD CONSTRAINT fk_aus_business
                FOREIGN KEY (business_id) REFERENCES agenda_businesses (id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_act_subscription') THEN
        ALTER TABLE agenda_credit_transactions
            ADD CONSTRAINT fk_act_subscription
                FOREIGN KEY (subscription_id) REFERENCES agenda_user_subscriptions (id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_agenda_bookings_business') THEN
        ALTER TABLE agenda_bookings
            ADD CONSTRAINT fk_agenda_bookings_business
                FOREIGN KEY (business_id) REFERENCES agenda_businesses (id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_agenda_bookings_service') THEN
        ALTER TABLE agenda_bookings
            ADD CONSTRAINT fk_agenda_bookings_service
                FOREIGN KEY (service_id) REFERENCES agenda_services (id) ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_agenda_bookings_user') THEN
        ALTER TABLE agenda_bookings
            ADD CONSTRAINT fk_agenda_bookings_user
                FOREIGN KEY (user_id) REFERENCES agenda_users (id) ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_agenda_bookings_subscription') THEN
        ALTER TABLE agenda_bookings
            ADD CONSTRAINT fk_agenda_bookings_subscription
                FOREIGN KEY (subscription_id) REFERENCES agenda_user_subscriptions (id) ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_agenda_credit_transactions_booking') THEN
        ALTER TABLE agenda_credit_transactions
            ADD CONSTRAINT fk_agenda_credit_transactions_booking
                FOREIGN KEY (booking_id) REFERENCES agenda_bookings (id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_agenda_staff_members_business') THEN
        ALTER TABLE agenda_staff_members
            ADD CONSTRAINT fk_agenda_staff_members_business
                FOREIGN KEY (business_id) REFERENCES agenda_businesses (id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_agenda_bookings_staff') THEN
        ALTER TABLE agenda_bookings
            ADD CONSTRAINT fk_agenda_bookings_staff
                FOREIGN KEY (staff_member_id) REFERENCES agenda_staff_members (id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_staff_status') THEN
        ALTER TABLE agenda_staff_members
            ADD CONSTRAINT chk_staff_status
            CHECK (status IN ('ACTIVO', 'PAUSADO', 'ARCHIVADO'));
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- Índices estándar (IF NOT EXISTS por si Hibernate ya los creó desde @Index)
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_agenda_users_tenant ON agenda_users (tenant_id);

CREATE INDEX IF NOT EXISTS idx_abc_category ON agenda_business_categories (category_id);

CREATE INDEX IF NOT EXISTS idx_agenda_businesses_bot_id ON agenda_businesses (bot_id);

CREATE INDEX IF NOT EXISTS idx_agenda_plans_business_activo ON agenda_plans (business_id, activo);

CREATE INDEX IF NOT EXISTS idx_aus_user_business_estado
    ON agenda_user_subscriptions (user_id, business_id, estado);

CREATE INDEX IF NOT EXISTS idx_aus_business_estado
    ON agenda_user_subscriptions (business_id, estado);

CREATE INDEX IF NOT EXISTS idx_act_subscription_created
    ON agenda_credit_transactions (subscription_id, created_at);

CREATE INDEX IF NOT EXISTS idx_agenda_bookings_business_fecha
    ON agenda_bookings (business_id, fecha_hora_inicio);

CREATE INDEX IF NOT EXISTS idx_agenda_bookings_user_estado
    ON agenda_bookings (user_id, estado, fecha_hora_inicio);

CREATE INDEX IF NOT EXISTS idx_agenda_loyalty_biz_user_estado
    ON agenda_loyalty_suggestions (business_id, user_id, estado);

CREATE INDEX IF NOT EXISTS idx_agenda_loyalty_biz_created
    ON agenda_loyalty_suggestions (business_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_agenda_notif_user_estado
    ON agenda_notifications (user_id, estado, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_agenda_notif_biz_created
    ON agenda_notifications (business_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_agenda_notif_tmpl_biz
    ON agenda_notification_templates (business_id);

CREATE INDEX IF NOT EXISTS idx_business_hours_business_id ON agenda_business_hours (business_id);

CREATE INDEX IF NOT EXISTS idx_agenda_business_photos_business
    ON agenda_business_photos (business_id, orden);

CREATE INDEX IF NOT EXISTS idx_agenda_tenant_accounts_access_code
    ON agenda_tenant_accounts (access_code);

-- ----------------------------------------------------------------------------
-- Índices parciales, GIN y expresiones (solo SQL)
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_agenda_categories_synonyms_gin
    ON agenda_categories USING GIN (synonyms jsonb_path_ops);

CREATE INDEX IF NOT EXISTS idx_agenda_categories_activo
    ON agenda_categories (activo) WHERE activo = TRUE;

CREATE INDEX IF NOT EXISTS idx_agenda_businesses_tenant_activo
    ON agenda_businesses (tenant_id, activo) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_agenda_businesses_nombre_lower
    ON agenda_businesses (LOWER(nombre));

CREATE INDEX IF NOT EXISTS idx_agenda_businesses_search_tags_gin
    ON agenda_businesses USING GIN (search_tags jsonb_path_ops);

CREATE INDEX IF NOT EXISTS idx_agenda_services_business_activo
    ON agenda_services (business_id, activo) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_agenda_plans_deleted_at
    ON agenda_plans (business_id, activo) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_agenda_bookings_slot
    ON agenda_bookings (business_id, service_id, fecha_hora_inicio)
    WHERE estado IN ('PENDING', 'CONFIRMED');

CREATE INDEX IF NOT EXISTS idx_agenda_bookings_subscription
    ON agenda_bookings (subscription_id)
    WHERE subscription_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_agenda_staff_members_business
    ON agenda_staff_members (business_id)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_agenda_outbox_pending
    ON agenda_outbox_events (status, created_at)
    WHERE status = 'PENDING';

CREATE UNIQUE INDEX IF NOT EXISTS uk_agenda_tenant_accounts_email
    ON agenda_tenant_accounts (email)
    WHERE email IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uk_agenda_tenant_accounts_numero
    ON agenda_tenant_accounts (numero)
    WHERE numero IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uk_agenda_tenant_accounts_google_linked_email
    ON agenda_tenant_accounts (google_linked_email)
    WHERE google_linked_email IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_agenda_businesses_public_slug
    ON agenda_businesses (public_slug)
    WHERE public_slug IS NOT NULL AND public_slug <> '';

-- ----------------------------------------------------------------------------
-- Datos legacy (bases creadas antes del slug / bot_id en entidades)
-- ----------------------------------------------------------------------------
UPDATE agenda_businesses
SET public_slug =
        lower(regexp_replace(coalesce(nombre, ''), '[^a-z0-9]+', '-', 'g')) || '-' || substring(id::text, 1, 8)
WHERE public_slug IS NULL OR public_slug = '';

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = current_schema() AND table_name = 'bot'
    ) THEN
        UPDATE agenda_businesses ab
        SET bot_id = b.id
        FROM bot b
        WHERE ab.bot_id IS NULL
          AND ab.tenant_id = b.tenant_id;
    END IF;
END $$;
