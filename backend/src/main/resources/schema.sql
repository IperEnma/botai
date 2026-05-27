-- Extensiones PG aplicadas por Spring SQL init (mode=always) ANTES de que Hibernate cree las tablas.
-- Idempotente: IF NOT EXISTS garantiza que no falla si ya existen.
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS btree_gist;
