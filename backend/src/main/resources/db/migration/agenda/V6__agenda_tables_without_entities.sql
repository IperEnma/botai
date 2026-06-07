-- Responsabilidad (V6): tablas sin entidad JPA (Hibernate no las crea).
-- Ver backend/docs/AGENDA_FLYWAY_MIGRATIONS.md

-- Idempotencia HTTP (AgendaIdempotencyFilter).
CREATE TABLE IF NOT EXISTS agenda_idempotency_keys (
    idempotency_key VARCHAR(128) PRIMARY KEY,
    status_code     INT NOT NULL,
    response_body   TEXT NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agenda_idempotency_created
    ON agenda_idempotency_keys (created_at);
