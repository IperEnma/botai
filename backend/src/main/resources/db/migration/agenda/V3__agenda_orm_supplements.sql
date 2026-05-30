-- Complementos que JPA no modela (misma filosofía: tablas = entidades Hibernate).
-- IF NOT EXISTS: solo para re-ejecutar Flyway en dev (clean-history); en prod cada script corre una vez.

-- Anti doble reserva (EXCLUDE GiST)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'excl_agenda_bookings_slot') THEN
        ALTER TABLE agenda_bookings
            ADD CONSTRAINT excl_agenda_bookings_slot
            EXCLUDE USING gist (
                business_id   WITH =,
                service_id    WITH =,
                tsrange(fecha_hora_inicio, fecha_hora_fin, '[)') WITH &&
            ) WHERE (estado IN ('PENDING', 'CONFIRMED'));
    END IF;
END $$;

-- Idempotencia HTTP (sin entidad JPA; AgendaIdempotencyFilter)
CREATE TABLE IF NOT EXISTS agenda_idempotency_keys (
    idempotency_key VARCHAR(128) PRIMARY KEY,
    status_code     INT NOT NULL,
    response_body   TEXT NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agenda_idempotency_created
    ON agenda_idempotency_keys (created_at);

-- Índices GIN / parciales / expresiones
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
