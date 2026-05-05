-- V12: branding (logo + color) + horarios del negocio

ALTER TABLE agenda_businesses
    ADD COLUMN IF NOT EXISTS logo_url   VARCHAR(500),
    ADD COLUMN IF NOT EXISTS color_primario VARCHAR(9);

CREATE TABLE IF NOT EXISTS agenda_business_hours (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id  UUID        NOT NULL REFERENCES agenda_businesses(id) ON DELETE CASCADE,
    dia_semana   SMALLINT    NOT NULL CHECK (dia_semana BETWEEN 0 AND 6),
    apertura     TIME,
    cierre       TIME,
    cerrado      BOOLEAN     NOT NULL DEFAULT false,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (business_id, dia_semana)
);

CREATE INDEX IF NOT EXISTS idx_business_hours_business_id ON agenda_business_hours(business_id);
