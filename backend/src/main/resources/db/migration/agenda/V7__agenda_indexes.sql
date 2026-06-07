-- Responsabilidad (V7): rendimiento — índices GIN / parciales / expresión que
-- Hibernate no genera. Índices simples → @Table(indexes=...). Idempotente.
-- Secuencia Flyway Agenda termina en V7 (greenfield). Ver AGENDA_FLYWAY_MIGRATIONS.md

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

CREATE INDEX IF NOT EXISTS idx_agenda_businesses_company_slug
    ON agenda_businesses (company_slug)
    WHERE deleted_at IS NULL AND activo = TRUE;

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

-- Reseñas por profesional: índice PARCIAL (solo filas con staff asignado).
CREATE INDEX IF NOT EXISTS idx_agenda_reviews_staff
    ON agenda_reviews (staff_member_id)
    WHERE staff_member_id IS NOT NULL;
