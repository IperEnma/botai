-- public_slug en agenda_businesses: consolidado en V1 (primer arranque).
-- Rellena slug inicial para filas heredadas sin slug; en BD nueva suele no afectar filas.

UPDATE agenda_businesses
SET public_slug =
        lower(regexp_replace(coalesce(nombre, ''), '[^a-z0-9]+', '-', 'g')) || '-' || substring(id::text, 1, 8)
WHERE public_slug IS NULL OR public_slug = '';

CREATE UNIQUE INDEX IF NOT EXISTS ux_agenda_businesses_public_slug
    ON agenda_businesses(public_slug)
    WHERE public_slug IS NOT NULL AND public_slug <> '';
