-- Extensiones PostgreSQL necesarias antes de que Hibernate cree columnas vector.
-- Spring Boot ejecuta este archivo en la fase de inicialización del DataSource,
-- antes de que JPA/Hibernate arranque. Todos los statements son idempotentes.
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS btree_gist;
