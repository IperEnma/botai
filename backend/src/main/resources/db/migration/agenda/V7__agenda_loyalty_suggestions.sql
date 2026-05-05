-- ============================================================================
-- V7__agenda_loyalty_suggestions.sql
-- Tabla de sugerencias de fidelización generadas por el motor de loyaltyengine.
--
-- Cada fila representa una señal de que un usuario ha alcanzado el umbral de
-- asistencias configurado en el negocio (loyalty_min_attendances) dentro de la
-- ventana temporal (loyalty_window_days). El negocio puede usar esta información
-- para contactar al cliente, sugerir renovación de plan o emitir un beneficio.
--
-- Flujo: BookingConfirmedEvent → BookingConfirmedEventListener →
--        LoyaltyDomainService.evaluar → INSERT aquí si triggered.
--
-- Solo se crea una sugerencia PENDING por (business_id, user_id) a la vez:
-- el listener verifica existencia antes de insertar.
-- ============================================================================

CREATE TABLE agenda_loyalty_suggestions (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id  UUID        NOT NULL,
    user_id      UUID        NOT NULL,
    trigger_rule VARCHAR(60) NOT NULL,
    estado       VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at   TIMESTAMP   NOT NULL DEFAULT now(),
    updated_at   TIMESTAMP   NOT NULL DEFAULT now()
);

-- Consulta principal: sugerencias pendientes por negocio/usuario
CREATE INDEX idx_agenda_loyalty_biz_user_estado
    ON agenda_loyalty_suggestions (business_id, user_id, estado);

-- Panel de admin: todas las sugerencias de un negocio ordenadas por fecha
CREATE INDEX idx_agenda_loyalty_biz_created
    ON agenda_loyalty_suggestions (business_id, created_at DESC);
