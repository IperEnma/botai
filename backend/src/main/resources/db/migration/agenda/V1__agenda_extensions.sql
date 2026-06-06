-- Extensiones PG (RAG pgvector, EXCLUDE btree_gist). Flyway V1; tablas = Hibernate.

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS btree_gist;
