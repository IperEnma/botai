-- ============================================================================
-- V6__agenda_bookings_slot_exclusion.sql
-- Cierra la race condition de double-booking entre usuarios con suscripciones
-- distintas que reservan el mismo slot simultáneamente.
--
-- PROBLEMA (documentado en V4): la validación de solapamiento en
-- BookingDomainService.validarDisponibilidad es best-effort — dos requests
-- concurrentes pueden pasar el check de aplicación y ambas insertar.
--
-- SOLUCIÓN: constraint EXCLUDE USING gist que delega la exclusividad en el
-- motor de PostgreSQL. Cuando dos transacciones intentan insertar bookings
-- activos con (business_id, service_id) iguales y rangos solapados, la segunda
-- recibe un error de violación de constraint, que el adapter convierte en
-- BookingSlotTakenException → HTTP 409.
--
-- NOTA FUTURA (multi-staff): si el negocio tiene N profesionales disponibles,
-- este constraint deberá reemplazarse por un mecanismo de capacidad por slot
-- (ej. contador + check). Por ahora la semántica "1 slot = 1 reserva" es
-- correcta para el modelo actual.
-- ============================================================================

-- btree_gist extiende GiST para permitir el operador = sobre tipos escalares
-- (UUID, TEXT, etc.) dentro de un EXCLUDE. Sin esta extensión solo se pueden
-- excluir tipos rango nativos.
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- El constraint aplica solo a bookings activos (PENDING / CONFIRMED).
-- Bookings CANCELLED, COMPLETED o NO_SHOW no bloquean el slot.
-- tsrange '[)' = intervalo cerrado en inicio, abierto en fin:
--   una reserva que termina a las 10:30 NO bloquea otra que empieza a las 10:30.
ALTER TABLE agenda_bookings
    ADD CONSTRAINT excl_agenda_bookings_slot
    EXCLUDE USING gist (
        business_id   WITH =,
        service_id    WITH =,
        tsrange(fecha_hora_inicio, fecha_hora_fin, '[)') WITH &&
    ) WHERE (estado IN ('PENDING', 'CONFIRMED'));
