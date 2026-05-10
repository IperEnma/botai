-- Añade la columna public_slug si todavía no existe.
-- Necesario para bases de datos creadas antes de que se consolidara en V1.
ALTER TABLE agenda_businesses ADD COLUMN IF NOT EXISTS public_slug VARCHAR(180);

-- Rellena slug inicial para filas heredadas sin slug.
UPDATE agenda_businesses
SET public_slug =
        lower(regexp_replace(coalesce(nombre, ''), '[^a-z0-9]+', '-', 'g')) || '-' || substring(id::text, 1, 8)
WHERE public_slug IS NULL OR public_slug = '';

CREATE UNIQUE INDEX IF NOT EXISTS ux_agenda_businesses_public_slug
    ON agenda_businesses(public_slug)
    WHERE public_slug IS NOT NULL AND public_slug <> '';
