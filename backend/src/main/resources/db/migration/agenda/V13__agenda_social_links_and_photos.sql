-- V13: galería de trabajos (máx 10 fotos en aplicación).
-- Redes sociales en agenda_businesses: consolidadas en V1 (primer arranque).

CREATE TABLE IF NOT EXISTS agenda_business_photos (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID         NOT NULL REFERENCES agenda_businesses(id) ON DELETE CASCADE,
    url         VARCHAR(500) NOT NULL,
    orden       SMALLINT     NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agenda_business_photos_business
    ON agenda_business_photos(business_id, orden);
