-- Responsabilidad: integridad de datos vía CHECK que Hibernate no genera
-- (columnas sin @Check en la entidad). Tablas = entidades Hibernate (creadas
-- antes de que Flyway corra; ver AgendaFlywayConfig). Idempotente.

-- Rango de rating de reseñas
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_agenda_reviews_rating') THEN
        ALTER TABLE agenda_reviews
            ADD CONSTRAINT chk_agenda_reviews_rating CHECK (rating BETWEEN 1 AND 5);
    END IF;
END $$;

-- Enums persistidos como string (EnumType.STRING / String)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_agenda_users_tipo_usuario') THEN
        ALTER TABLE agenda_users
            ADD CONSTRAINT chk_agenda_users_tipo_usuario CHECK (tipo_usuario IN ('ADMIN', 'CLIENT'));
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_agenda_staff_members_status') THEN
        ALTER TABLE agenda_staff_members
            ADD CONSTRAINT chk_agenda_staff_members_status CHECK (status IN ('ACTIVO', 'PAUSADO'));
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_agenda_notifications_canal') THEN
        ALTER TABLE agenda_notifications
            ADD CONSTRAINT chk_agenda_notifications_canal CHECK (canal IN ('IN_APP', 'EMAIL', 'PUSH'));
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_agenda_notifications_estado') THEN
        ALTER TABLE agenda_notifications
            ADD CONSTRAINT chk_agenda_notifications_estado CHECK (estado IN ('PENDING', 'SENT', 'FAILED'));
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_agenda_loyalty_suggestions_estado') THEN
        ALTER TABLE agenda_loyalty_suggestions
            ADD CONSTRAINT chk_agenda_loyalty_suggestions_estado CHECK (estado IN ('PENDING', 'SENT', 'DISMISSED'));
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_agenda_outbox_events_status') THEN
        ALTER TABLE agenda_outbox_events
            ADD CONSTRAINT chk_agenda_outbox_events_status CHECK (status IN ('PENDING', 'PROCESSED'));
    END IF;
END $$;

-- Rangos numéricos
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_agenda_business_settings_expiration') THEN
        ALTER TABLE agenda_business_settings
            ADD CONSTRAINT chk_agenda_business_settings_expiration
            CHECK (expiration_alert_days >= 0 AND expiration_alert_credits >= 0);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_agenda_business_photos_orden') THEN
        ALTER TABLE agenda_business_photos
            ADD CONSTRAINT chk_agenda_business_photos_orden CHECK (orden >= 0);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_agenda_otp_failed_attempts') THEN
        ALTER TABLE agenda_otp_challenges
            ADD CONSTRAINT chk_agenda_otp_failed_attempts CHECK (failed_attempts >= 0);
    END IF;
END $$;

-- Coherencia de horarios (día abierto debe tener apertura y cierre)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_agenda_business_hours_rango') THEN
        ALTER TABLE agenda_business_hours
            ADD CONSTRAINT chk_agenda_business_hours_rango
            CHECK (cerrado = TRUE OR (apertura IS NOT NULL AND cierre IS NOT NULL));
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_agenda_business_hours_rango2') THEN
        ALTER TABLE agenda_business_hours
            ADD CONSTRAINT chk_agenda_business_hours_rango2
            CHECK ((apertura2 IS NULL AND cierre2 IS NULL)
                   OR (apertura2 IS NOT NULL AND cierre2 IS NOT NULL));
    END IF;
END $$;
