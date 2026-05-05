-- ============================================================================
-- V9__agenda_idempotency.sql
-- Almacena Idempotency-Key de reservas para evitar reservas duplicadas por
-- reintentos de red en POST /me/*/bookings.
--
-- El cliente envía el header "Idempotency-Key: <uuid>".
-- Si la clave ya existe, se devuelve la respuesta original cacheada.
-- Limpieza automática: una tarea programada elimina filas con más de 24 horas.
-- ============================================================================

CREATE TABLE agenda_idempotency_keys (
    idempotency_key VARCHAR(128)  PRIMARY KEY,
    status_code     INT           NOT NULL,
    response_body   TEXT          NOT NULL,
    created_at      TIMESTAMP     NOT NULL DEFAULT now()
);

CREATE INDEX idx_agenda_idempotency_created
    ON agenda_idempotency_keys (created_at);
