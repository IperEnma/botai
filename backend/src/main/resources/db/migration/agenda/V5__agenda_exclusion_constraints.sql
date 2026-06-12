-- Responsabilidad (V5): EXCLUDE GiST anti doble-reserva. Requiere btree_gist (V1).
-- Ver backend/docs/AGENDA_FLYWAY_MIGRATIONS.md

-- Anti doble reserva por negocio+servicio.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'excl_agenda_bookings_slot') THEN
        ALTER TABLE agenda_bookings
            ADD CONSTRAINT excl_agenda_bookings_slot
            EXCLUDE USING gist (
                business_id   WITH =,
                service_id    WITH =,
                tsrange(fecha_hora_inicio, fecha_hora_fin, '[)') WITH &&
            ) WHERE (estado IN ('PENDING', 'CONFIRMED'));
    END IF;
END $$;

-- Anti doble reserva por PROFESIONAL — agenda única por staff a nivel tenant.
-- Sin business_id en el EXCLUDE: un staff multi-sucursal no puede tener dos
-- reservas activas solapadas aunque vivan en sucursales distintas (regla de la
-- spec: "la agenda de un profesional es única dentro del tenant").
-- JpaBookingRepository espera este nombre para traducir la violación a BookingSlotTakenException.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'excl_agenda_bookings_staff_slot') THEN
        ALTER TABLE agenda_bookings
            ADD CONSTRAINT excl_agenda_bookings_staff_slot
            EXCLUDE USING gist (
                staff_member_id WITH =,
                tsrange(fecha_hora_inicio, fecha_hora_fin, '[)') WITH &&
            ) WHERE (estado IN ('PENDING', 'CONFIRMED') AND staff_member_id IS NOT NULL);
    END IF;
END $$;
