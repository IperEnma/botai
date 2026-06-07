-- Imágenes subidas (logo, banner, avatares) persistidas en Postgres para prod (Render/Neon).
-- storage_key = path relativo sin /uploads/ (ej. businesses/{id}/{file}.jpg)

CREATE TABLE IF NOT EXISTS agenda_uploaded_files (
    storage_key   VARCHAR(512) PRIMARY KEY,
    content_type  VARCHAR(128) NOT NULL,
    data          BYTEA NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT now()
);
