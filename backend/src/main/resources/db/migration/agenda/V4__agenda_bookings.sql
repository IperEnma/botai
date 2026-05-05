-- =============================================================================
-- V4 — Reservas (Sprint 3, Slice 1)
-- =============================================================================
-- Crea agenda_bookings, que referencia business/service/user y opcionalmente la
-- suscripción con la que se pagó la sesión. La FK a suscripción es RESTRICT
-- para no perder trazabilidad del movimiento en agenda_credit_transactions.
--
-- También se agrega la FK opcional booking_id en agenda_credit_transactions
-- (la tabla ya tenía la columna; aprovechamos este V para activar la FK ahora
-- que bookings existe). Ver V3 donde se decidió dejar esto para Sprint 3.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- agenda_bookings — reservas individuales.
--   * PENDING: creada pero no confirmada (no descuenta).
--   * CONFIRMED: reserva activa (ya descontó crédito si aplica).
--   * CANCELLED: cancelada (puede haber devuelto crédito según la política).
--   * COMPLETED: sesión ocurrida (marcaje manual o job futuro).
--   * NO_SHOW: el usuario no se presentó (política del negocio).
-- ----------------------------------------------------------------------------
CREATE TABLE agenda_bookings (
    id                UUID         NOT NULL DEFAULT gen_random_uuid(),
    business_id       UUID         NOT NULL,
    service_id        UUID         NOT NULL,
    user_id           UUID         NOT NULL,
    subscription_id   UUID,                                 -- null si pagó con plata suelta / admin lo creó
    fecha_hora_inicio TIMESTAMP    NOT NULL,
    fecha_hora_fin    TIMESTAMP    NOT NULL,
    estado            VARCHAR(16)  NOT NULL DEFAULT 'CONFIRMED',
    notas             TEXT,
    cancelada_at      TIMESTAMP,
    completada_at     TIMESTAMP,
    created_at        TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at        TIMESTAMP    NOT NULL DEFAULT now(),

    CONSTRAINT pk_agenda_bookings PRIMARY KEY (id),

    CONSTRAINT fk_agenda_bookings_business
        FOREIGN KEY (business_id) REFERENCES agenda_businesses (id) ON DELETE CASCADE,

    CONSTRAINT fk_agenda_bookings_service
        FOREIGN KEY (service_id) REFERENCES agenda_services (id) ON DELETE RESTRICT,

    CONSTRAINT fk_agenda_bookings_user
        FOREIGN KEY (user_id) REFERENCES agenda_users (id) ON DELETE RESTRICT,

    -- RESTRICT: una suscripción con bookings asociadas no puede ser eliminada;
    -- queda auditable vía el soft-state (estado=CANCELLED/EXPIRED) en su tabla.
    CONSTRAINT fk_agenda_bookings_subscription
        FOREIGN KEY (subscription_id) REFERENCES agenda_user_subscriptions (id) ON DELETE RESTRICT,

    CONSTRAINT ck_agenda_bookings_estado
        CHECK (estado IN ('PENDING','CONFIRMED','CANCELLED','COMPLETED','NO_SHOW')),

    CONSTRAINT ck_agenda_bookings_horario
        CHECK (fecha_hora_fin > fecha_hora_inicio)
);

-- Calendario del negocio: "mostrame todas las reservas del día".
CREATE INDEX idx_agenda_bookings_business_fecha
    ON agenda_bookings (business_id, fecha_hora_inicio);

-- "Mis citas" del usuario final.
CREATE INDEX idx_agenda_bookings_user_estado
    ON agenda_bookings (user_id, estado, fecha_hora_inicio);

-- Para validar solapamiento dentro del mismo negocio/servicio en un horario.
-- No usamos UNIQUE porque dos usuarios distintos pueden reservar el mismo
-- servicio a la misma hora si el negocio tiene varios staff (por ahora no
-- modelado, pero dejamos espacio). La exclusividad se valida en dominio.
CREATE INDEX idx_agenda_bookings_slot
    ON agenda_bookings (business_id, service_id, fecha_hora_inicio)
    WHERE estado IN ('PENDING','CONFIRMED');

-- Historial por suscripción: auditoría de uso del plan.
CREATE INDEX idx_agenda_bookings_subscription
    ON agenda_bookings (subscription_id)
    WHERE subscription_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- Activamos la FK de agenda_credit_transactions.booking_id ahora que la tabla
-- agenda_bookings existe. ON DELETE SET NULL para no romper el libro mayor si
-- un booking fuese borrado físicamente en el futuro (no lo hacemos hoy, pero
-- preservar trazabilidad del movimiento es una invariante).
-- ----------------------------------------------------------------------------
ALTER TABLE agenda_credit_transactions
    ADD CONSTRAINT fk_agenda_credit_transactions_booking
        FOREIGN KEY (booking_id) REFERENCES agenda_bookings (id) ON DELETE SET NULL;
