-- Responsabilidad (V1): extensiones PostgreSQL. Tablas agenda_* = Hibernate (ddl-auto).
-- Ver backend/docs/AGENDA_FLYWAY_MIGRATIONS.md

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS btree_gist;
