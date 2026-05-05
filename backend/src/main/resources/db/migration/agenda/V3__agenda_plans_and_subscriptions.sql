-- ============================================================================
-- V3__agenda_plans_and_subscriptions.sql
-- Sprint 2 · Slice 1 — Planes, Suscripciones y Transacciones de crédito.
-- Schema: public  |  Prefijo: agenda_  |  Aislado del bot.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- agenda_plans — planes que ofrece un negocio.
-- Un plan pertenece a UN negocio (los planes no son globales). Contempla los
-- 4 tipos del plan maestro: ILIMITADO_MENSUAL / POR_CREDITOS / SOLO_RESERVA /
-- MIXTO (ver CreditDomainService en Slice 2).
--
-- Campos nullable:
--   - tier (opcional: no todos los planes tienen VIP/GOLDEN/PLATA)
--   - total_creditos: NULL solo para ILIMITADO_MENSUAL y SOLO_RESERVA;
--     NOT NULL para POR_CREDITOS y MIXTO (validado a nivel de dominio).
-- ----------------------------------------------------------------------------
CREATE TABLE agenda_plans (
    id               UUID         NOT NULL DEFAULT gen_random_uuid(),
    business_id      UUID         NOT NULL,
    nombre_plan      VARCHAR(255) NOT NULL,
    tipo             VARCHAR(24)  NOT NULL,          -- ILIMITADO_MENSUAL | POR_CREDITOS | SOLO_RESERVA | MIXTO
    tier             VARCHAR(16),                    -- VIP | GOLDEN | PLATA (opcional)
    total_creditos   INTEGER,
    validez_dias     INTEGER      NOT NULL,
    precio           NUMERIC(12,2) NOT NULL,
    activo           BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at       TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT pk_agenda_plans PRIMARY KEY (id),
    CONSTRAINT fk_agenda_plans_business
        FOREIGN KEY (business_id) REFERENCES agenda_businesses (id) ON DELETE CASCADE,
    CONSTRAINT ck_agenda_plans_tipo
        CHECK (tipo IN ('ILIMITADO_MENSUAL','POR_CREDITOS','SOLO_RESERVA','MIXTO')),
    CONSTRAINT ck_agenda_plans_tier
        CHECK (tier IS NULL OR tier IN ('VIP','GOLDEN','PLATA')),
    CONSTRAINT ck_agenda_plans_validez CHECK (validez_dias > 0),
    CONSTRAINT ck_agenda_plans_precio CHECK (precio >= 0),
    CONSTRAINT ck_agenda_plans_creditos CHECK (total_creditos IS NULL OR total_creditos >= 0)
);
CREATE INDEX idx_agenda_plans_business_activo
    ON agenda_plans (business_id, activo);

-- ----------------------------------------------------------------------------
-- agenda_user_subscriptions — "monedero" del usuario en un negocio.
-- Es la fila sobre la que se toma PESSIMISTIC_WRITE al confirmar reservas
-- (Sprint 3) para evitar doble descuento.
-- ----------------------------------------------------------------------------
CREATE TABLE agenda_user_subscriptions (
    id                 UUID        NOT NULL DEFAULT gen_random_uuid(),
    user_id            UUID        NOT NULL,
    plan_id            UUID        NOT NULL,
    business_id        UUID        NOT NULL,
    saldo_actual       INTEGER     NOT NULL DEFAULT 0,
    fecha_inicio       TIMESTAMP   NOT NULL,
    fecha_expiracion   TIMESTAMP   NOT NULL,
    estado             VARCHAR(16) NOT NULL,         -- ACTIVE | EXPIRED | CANCELLED
    created_at         TIMESTAMP   NOT NULL DEFAULT now(),
    updated_at         TIMESTAMP   NOT NULL DEFAULT now(),
    CONSTRAINT pk_agenda_user_subscriptions PRIMARY KEY (id),
    CONSTRAINT fk_aus_user
        FOREIGN KEY (user_id) REFERENCES agenda_users (id) ON DELETE RESTRICT,
    CONSTRAINT fk_aus_plan
        FOREIGN KEY (plan_id) REFERENCES agenda_plans (id) ON DELETE RESTRICT,
    CONSTRAINT fk_aus_business
        FOREIGN KEY (business_id) REFERENCES agenda_businesses (id) ON DELETE CASCADE,
    CONSTRAINT ck_aus_estado CHECK (estado IN ('ACTIVE','EXPIRED','CANCELLED')),
    CONSTRAINT ck_aus_saldo CHECK (saldo_actual >= 0),
    CONSTRAINT ck_aus_fechas CHECK (fecha_expiracion >= fecha_inicio)
);
CREATE INDEX idx_aus_user_business_estado
    ON agenda_user_subscriptions (user_id, business_id, estado);
CREATE INDEX idx_aus_business_estado
    ON agenda_user_subscriptions (business_id, estado);

-- ----------------------------------------------------------------------------
-- agenda_credit_transactions — auditoría inmutable de movimientos de saldo.
-- Una suscripción "ILIMITADO_MENSUAL" igual genera filas con monto=0 para
-- trazabilidad (ver CreditDomainService.descontar).
--
-- NO se declara FK a agenda_bookings porque todavía no existe (Sprint 3).
-- Cuando se cree la tabla, se añadirá la FK en una migración futura.
-- ----------------------------------------------------------------------------
CREATE TABLE agenda_credit_transactions (
    id                UUID        NOT NULL DEFAULT gen_random_uuid(),
    subscription_id   UUID        NOT NULL,
    monto             INTEGER     NOT NULL,         -- signo indica débito (-) o crédito (+)
    motivo            VARCHAR(24) NOT NULL,         -- RESERVA | CANCELACION_DEVUELTA | AJUSTE_ADMIN | COMPRA
    booking_id        UUID,                         -- nullable, FK diferida al Sprint 3
    created_at        TIMESTAMP   NOT NULL DEFAULT now(),
    updated_at        TIMESTAMP   NOT NULL DEFAULT now(),
    CONSTRAINT pk_agenda_credit_transactions PRIMARY KEY (id),
    CONSTRAINT fk_act_subscription
        FOREIGN KEY (subscription_id) REFERENCES agenda_user_subscriptions (id) ON DELETE CASCADE,
    CONSTRAINT ck_act_motivo
        CHECK (motivo IN ('RESERVA','CANCELACION_DEVUELTA','AJUSTE_ADMIN','COMPRA'))
);
CREATE INDEX idx_act_subscription_created
    ON agenda_credit_transactions (subscription_id, created_at);
