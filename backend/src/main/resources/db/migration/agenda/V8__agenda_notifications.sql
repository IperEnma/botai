-- ============================================================================
-- V8__agenda_notifications.sql
-- Notificaciones in-app enviadas a usuarios y plantillas editables por negocio.
--
-- agenda_notifications:
--   Registro de cada notificación generada. Estado: PENDING → SENT / FAILED.
--   Canal inicial: IN_APP. EMAIL/PUSH quedan stubbed para fases futuras.
--
-- agenda_notification_templates:
--   Plantillas configuradas por cada negocio para los distintos eventos
--   (EXPIRACION_PRONTO, SALDO_BAJO, LOYALTY_TRIGGERED, ...).
--   El cuerpo puede incluir placeholders: {dias}, {saldo}, {nombre}.
--   Constraint UNIQUE (business_id, codigo, canal) evita duplicados.
-- ============================================================================

CREATE TABLE agenda_notifications (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID         NOT NULL,
    user_id     UUID         NOT NULL,
    canal       VARCHAR(20)  NOT NULL DEFAULT 'IN_APP',
    titulo      VARCHAR(255) NOT NULL,
    cuerpo      TEXT         NOT NULL,
    estado      VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE INDEX idx_agenda_notif_user_estado
    ON agenda_notifications (user_id, estado, created_at DESC);

CREATE INDEX idx_agenda_notif_biz_created
    ON agenda_notifications (business_id, created_at DESC);

CREATE TABLE agenda_notification_templates (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID         NOT NULL,
    codigo      VARCHAR(60)  NOT NULL,
    canal       VARCHAR(20)  NOT NULL DEFAULT 'IN_APP',
    titulo      VARCHAR(255) NOT NULL,
    cuerpo      TEXT         NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT uq_agenda_notif_template UNIQUE (business_id, codigo, canal)
);

CREATE INDEX idx_agenda_notif_tmpl_biz
    ON agenda_notification_templates (business_id);
