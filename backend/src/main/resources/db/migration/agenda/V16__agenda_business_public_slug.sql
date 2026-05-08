-- V16: public slug estable para link público de agenda por negocio

ALTER TABLE agenda_businesses
    ADD COLUMN IF NOT EXISTS public_slug VARCHAR(180);

-- Generar slug inicial para negocios existentes (estable y único por id).
-- Formato: <slug-nombre>-<8chars-id>
UPDATE agenda_businesses
SET public_slug =
        lower(regexp_replace(coalesce(nombre, ''), '[^a-z0-9]+', '-', 'g')) || '-' || substring(id::text, 1, 8)
WHERE public_slug IS NULL OR public_slug = '';

CREATE UNIQUE INDEX IF NOT EXISTS ux_agenda_businesses_public_slug
    ON agenda_businesses(public_slug)
    WHERE public_slug IS NOT NULL AND public_slug <> '';

