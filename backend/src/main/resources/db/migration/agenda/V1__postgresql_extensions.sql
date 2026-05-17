-- Extensiones PG del módulo AGENDA (y RAG pgvector en knowledge_chunk).
-- Flyway aplica esta migración al arrancar (idempotente).
-- En local, start-dev.ps1 la ejecuta también ANTES del backend: Hibernate corre antes que Flyway
-- (defer-datasource-initialization) y necesita vector al crear columnas embedding.

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS btree_gist;
