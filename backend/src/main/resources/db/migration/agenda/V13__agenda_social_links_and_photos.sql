-- V13: redes sociales del negocio + galería de trabajos (máx 10 fotos)

ALTER TABLE agenda_businesses
    ADD COLUMN IF NOT EXISTS instagram_url VARCHAR(500),
    ADD COLUMN IF NOT EXISTS tiktok_url    VARCHAR(500),
    ADD COLUMN IF NOT EXISTS facebook_url  VARCHAR(500);

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
