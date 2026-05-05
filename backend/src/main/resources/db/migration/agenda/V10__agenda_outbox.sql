-- ============================================================================
-- V10__agenda_outbox.sql
-- Tabla de outbox para garantizar entrega at-least-once de eventos de dominio.
--
-- Cuando CreateBookingUseCase confirma una reserva, persiste un registro aquí
-- dentro de la misma transacción. Un scheduler (OutboxEventScheduler) lee los
-- eventos PENDING y los publica vía ApplicationEventPublisher, marcándolos
-- como PROCESSED. Si el scheduler falla antes de marcar, el evento se reintenta.
-- Los listeners son idempotentes (deduplicación por business+user).
-- ============================================================================

CREATE TABLE agenda_outbox_events (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type    VARCHAR(100) NOT NULL,
    payload       JSONB        NOT NULL,
    status        VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    created_at    TIMESTAMP    NOT NULL DEFAULT now(),
    processed_at  TIMESTAMP
);

CREATE INDEX idx_agenda_outbox_pending
    ON agenda_outbox_events (status, created_at)
    WHERE status = 'PENDING';
